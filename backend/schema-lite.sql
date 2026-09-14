-- SJK-TRM v2.0-lite. Instalasi baru ATAU tambahan pada v1 dalam proyek Supabase yang sama.
-- Jalankan sekali melalui SQL Editor. Tabel v1 tidak dihapus, diubah, atau dipakai ulang.
-- Kode sumber public boleh dipublikasikan; data, akun, draf, dan kunci kasus tidak boleh.
begin;
create table if not exists public.sjk_staff (
 user_id uuid primary key references auth.users(id),
 display_name text not null check(length(display_name) between 1 and 80),
 role text not null check(role in ('admin','assistant')), active boolean not null default true
);
create or replace function public.sjk_is_staff() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.sjk_staff where user_id=auth.uid() and active);
$$;
create or replace function public.sjk_is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.sjk_staff where user_id=auth.uid() and active and role='admin');
$$;
alter table public.sjk_staff enable row level security;
-- Nama policy v2 tersendiri; aman berdampingan dengan policy staff v1.
create policy sjk_lite_staff_select on public.sjk_staff for select to authenticated
 using (public.sjk_is_staff() and (user_id=auth.uid() or public.sjk_is_admin()));
revoke all on public.sjk_staff from anon,authenticated;
grant select on public.sjk_staff to authenticated;
create table public.sjk_lite_protocol (
 id integer primary key check(id=1),version text not null default 'v2.0-lite' check(version='v2.0-lite'),
 mode text not null default 'OFF' check(mode in ('OFF','PILOT','MAIN')),
 ethics_reference text not null default '' check(length(ethics_reference)<=200),
 pilot_ready boolean not null default false,updated_at timestamptz not null default now(),
 check(mode='OFF' or length(trim(ethics_reference))>=3),check(mode<>'MAIN' or pilot_ready)
);
insert into public.sjk_lite_protocol(id) values(1);
create table public.sjk_lite_groups (
 id uuid primary key default gen_random_uuid(),class_code text not null check(class_code in ('E1','E2')),
 group_code text not null check(group_code ~ '^G[0-9]{2,3}$'), group_size integer not null check(group_size between 1 and 6),
 stage text not null check(stage in ('PILOT','MAIN')), arm text not null check(arm in ('A','B')),
 allocation_reference text not null check(length(trim(allocation_reference)) between 3 and 200),
 baseline_score integer check(baseline_score between 0 and 4),consent_active boolean not null default true,
 created_by uuid not null default auth.uid() references auth.users(id),created_at timestamptz not null default now(),
 unique(class_code,group_code,stage)
);
create table public.sjk_lite_records (
 id uuid primary key default gen_random_uuid(),group_id uuid not null references public.sjk_lite_groups(id),
 task text not null check(task in ('K1','K2')),session_date date not null,
 result text not null check(result in ('SUCCESS','TIMEOUT','NOT_RUN','TECHNICAL_INVALID','PROTOCOL_INVALID')),
 duration_s numeric check(duration_s>=0 and duration_s<=600),verified boolean not null,
 reasoning_score integer check(reasoning_score between 0 and 4),hints integer check(hints between 0 and 3),
 fidelity text not null check(fidelity in ('YES','NO','UNKNOWN')),notes text not null default '' check(length(notes)<=2000),
 source text not null check(source in ('WEB','PAPER')),entry_seconds integer not null check(entry_seconds>=0),
 version text not null default 'v2.0-lite' check(version='v2.0-lite'),
 supersedes_id uuid unique references public.sjk_lite_records(id),revision_reason text not null default '' check(length(revision_reason)<=2000),
 created_by uuid not null default auth.uid() references auth.users(id),created_at timestamptz not null default now(),
 check((result='SUCCESS' and verified) or (result<>'SUCCESS' and not verified and duration_s is null)),
 check(supersedes_id is null or length(trim(revision_reason))>0),
 check((result in ('SUCCESS','TIMEOUT') and fidelity='YES') or length(trim(notes))>0),
 check(result not in ('SUCCESS','TIMEOUT') or reasoning_score is not null or length(trim(notes))>0),
 check(task<>'K2' or coalesce(hints,0)=0 or fidelity<>'YES')
);
create unique index sjk_lite_first_attempt on public.sjk_lite_records(group_id,task) where supersedes_id is null;
create index sjk_lite_record_group on public.sjk_lite_records(group_id,task);
create table public.sjk_lite_audit (
 id bigint generated always as identity primary key,table_name text not null,operation text not null,
 record_id text,actor uuid,created_at timestamptz not null default now(),old_row jsonb,new_row jsonb
);
create function public.sjk_lite_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare g public.sjk_lite_groups; p public.sjk_lite_protocol; previous public.sjk_lite_records;
begin
 if tg_table_name='sjk_lite_groups' then
  if tg_op='INSERT' then
   if not new.consent_active then raise exception 'Daftarkan hanya kelompok dengan persetujuan aktif'; end if;
   new.created_by=auth.uid();new.created_at=now();
  else
   if (to_jsonb(new)-'consent_active') is distinct from (to_jsonb(old)-'consent_active') then raise exception 'Alokasi kelompok tetap; hanya penarikan persetujuan dapat diubah'; end if;
   if not old.consent_active and new.consent_active then raise exception 'Penarikan tidak diaktifkan kembali melalui dashboard'; end if;
  end if;
 elsif tg_table_name='sjk_lite_protocol' then
  new.updated_at=now();
 elsif tg_table_name='sjk_lite_records' then
  select * into g from public.sjk_lite_groups where id=new.group_id for update;
  if not found or not g.consent_active then raise exception 'Kelompok tidak tersedia atau persetujuan ditarik'; end if;
  select * into p from public.sjk_lite_protocol where id=1 for share;
  if new.session_date>current_date then raise exception 'Tanggal pelaksanaan belum terjadi'; end if;
  if new.supersedes_id is null then
   if p.mode='OFF' or p.mode<>g.stage then raise exception 'Mode pengambilan data tidak sesuai'; end if;
  else
   select * into previous from public.sjk_lite_records where id=new.supersedes_id for update;
   if not found or previous.group_id<>new.group_id or previous.task<>new.task then raise exception 'Koreksi harus untuk kelompok dan tugas yang sama'; end if;
   if exists(select 1 from public.sjk_lite_records where supersedes_id=new.supersedes_id) then raise exception 'Rekaman sudah dikoreksi'; end if;
  end if;
  if g.arm='B' and coalesce(new.hints,0)>0 and new.fidelity='YES' then raise exception 'Bantuan pada B harus ditandai sebagai penyimpangan'; end if;
  if new.task='K2' and new.result in ('SUCCESS','TIMEOUT') and not exists(
   select 1 from public.sjk_lite_records r where r.group_id=new.group_id and r.task='K1' and r.result in ('SUCCESS','TIMEOUT')
    and r.session_date<new.session_date and not exists(select 1 from public.sjk_lite_records q where q.supersedes_id=r.id)
  ) then raise exception 'K2 memerlukan K1 yang sah pada tanggal sebelumnya'; end if;
  new.created_by=auth.uid();new.created_at=now();
 end if;
 return new;
end; $$;
create trigger sjk_lite_group_guard before insert or update on public.sjk_lite_groups for each row execute function public.sjk_lite_guard();
create trigger sjk_lite_protocol_guard before update on public.sjk_lite_protocol for each row execute function public.sjk_lite_guard();
create trigger sjk_lite_record_guard before insert on public.sjk_lite_records for each row execute function public.sjk_lite_guard();
create function public.sjk_lite_audit_write() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.sjk_lite_audit(table_name,operation,record_id,actor,old_row,new_row)
 values(tg_table_name,tg_op,new.id::text,auth.uid(),case when tg_op='UPDATE' then to_jsonb(old) else null end,to_jsonb(new));return new;
end; $$;
create trigger sjk_lite_groups_audit after insert or update on public.sjk_lite_groups for each row execute function public.sjk_lite_audit_write();
create trigger sjk_lite_protocol_audit after update on public.sjk_lite_protocol for each row execute function public.sjk_lite_audit_write();
create trigger sjk_lite_records_audit after insert on public.sjk_lite_records for each row execute function public.sjk_lite_audit_write();
alter table public.sjk_lite_groups enable row level security;
alter table public.sjk_lite_records enable row level security;
alter table public.sjk_lite_protocol enable row level security;
alter table public.sjk_lite_audit enable row level security;
revoke all on public.sjk_lite_groups,public.sjk_lite_records,public.sjk_lite_protocol,public.sjk_lite_audit from anon,authenticated;
grant select,insert on public.sjk_lite_groups,public.sjk_lite_records to authenticated;
grant update(consent_active) on public.sjk_lite_groups to authenticated;
grant select on public.sjk_lite_protocol,public.sjk_lite_audit to authenticated;
grant update(mode,ethics_reference,pilot_ready) on public.sjk_lite_protocol to authenticated;
create policy lite_groups_read on public.sjk_lite_groups for select to authenticated using(public.sjk_is_staff());
create policy lite_groups_insert on public.sjk_lite_groups for insert to authenticated with check(public.sjk_is_admin());
create policy lite_groups_update on public.sjk_lite_groups for update to authenticated using(public.sjk_is_admin()) with check(public.sjk_is_admin());
create policy lite_records_read on public.sjk_lite_records for select to authenticated using(public.sjk_is_staff() and exists(select 1 from public.sjk_lite_groups g where g.id=group_id and g.consent_active));
create policy lite_records_insert on public.sjk_lite_records for insert to authenticated with check(public.sjk_is_staff() and exists(select 1 from public.sjk_lite_groups g where g.id=group_id and g.consent_active));
create policy lite_protocol_read on public.sjk_lite_protocol for select to authenticated using(public.sjk_is_staff());
create policy lite_protocol_update on public.sjk_lite_protocol for update to authenticated using(public.sjk_is_admin()) with check(public.sjk_is_admin());
create policy lite_audit_read on public.sjk_lite_audit for select to authenticated using(public.sjk_is_admin());
revoke all on function public.sjk_is_staff(),public.sjk_is_admin(),public.sjk_lite_guard(),public.sjk_lite_audit_write() from public,anon,authenticated;
grant execute on function public.sjk_is_staff(),public.sjk_is_admin() to authenticated;
commit;
