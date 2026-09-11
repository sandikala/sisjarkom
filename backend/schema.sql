-- SJK-TRM Web v1.0 — jalankan sekali pada proyek Supabase baru melalui SQL Editor.
-- Dataset tunggal untuk semester/protokol ini. Gunakan proyek/schema terpisah untuk kohort baru.
begin;
create table public.sjk_staff (
 user_id uuid primary key references auth.users(id),
 display_name text not null check(length(display_name) between 1 and 80),
 role text not null check(role in ('admin','assistant')),
 active boolean not null default true
);
create function public.sjk_is_staff() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.sjk_staff where user_id=auth.uid() and active);
$$;
create function public.sjk_is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.sjk_staff where user_id=auth.uid() and active and role='admin');
$$;
create table public.sjk_protocol (
 id integer primary key check(id=1), protocol_version text not null default 'v1.0',
 ethics_reference text not null default '', pilot_ready boolean not null default false,
 research_active boolean not null default false, seed integer not null default 20260908,
 frozen_at timestamptz, updated_at timestamptz not null default now(),
 check(not research_active or (length(trim(ethics_reference))>=3 and pilot_ready and frozen_at is not null))
);
insert into public.sjk_protocol(id) values(1);
create table public.sjk_participants (
 participant_id text primary key check(participant_id ~ '^P[A-Z0-9]{5,11}$'),
 class_code text not null check(class_code in ('E1','E2','BAU')),
 group_id text not null check(group_id ~ '^G[0-9]{2,3}$'),
 consent_status text not null check(consent_status in ('CONSENTED','DECLINED','WITHDRAWN')),
 prior_network_exp text check(prior_network_exp in ('none','basic','experienced')),
 prior_linux_exp text check(prior_linux_exp in ('none','basic','experienced')),
 pretest_form text, pretest_score numeric check(pretest_score between 0 and 100),
 common_assessment_1 numeric check(common_assessment_1 between 0 and 100),
 common_assessment_2 numeric check(common_assessment_2 between 0 and 100),
 transfer_score numeric check(transfer_score between 0 and 100),
 posttest_form text, posttest_score numeric check(posttest_score between 0 and 100),
 notes text not null default '' check(length(notes)<=2000),
 created_by uuid not null default auth.uid() references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.sjk_assignments (
 class_code text not null check(class_code in ('E1','E2')),group_id text not null check(group_id ~ '^G[0-9]{2,3}$'),
 module_id integer not null check(module_id between 12 and 15),
 sequence text not null check(sequence in ('S1','S2')),
 condition text not null check(condition in ('Adaptive','Standard')),
 fault_id text not null, seed integer not null, protocol_version text not null,
 frozen_at timestamptz not null default now(),
 primary key(class_code,group_id,module_id),
 check(fault_id ~ ('^F'||module_id::text||'[AB]$')),
 check(condition=case when ((module_id%2=0)=(sequence='S1')) then 'Adaptive' else 'Standard' end)
);
create function public.sjk_freeze_assignments(p_rows jsonb,p_seed integer) returns integer language plpgsql security definer set search_path='' as $$
declare n integer;
begin
 if not public.sjk_is_admin() then raise exception 'Hanya admin yang dapat membekukan assignment'; end if;
 perform 1 from public.sjk_protocol where id=1 for update;
 if exists(select 1 from public.sjk_assignments) or (select frozen_at is not null from public.sjk_protocol where id=1) then raise exception 'Assignment sudah dibekukan. Jangan ubah setelah outcome diketahui.'; end if;
 if jsonb_typeof(p_rows)<>'array' or jsonb_array_length(p_rows)=0 or jsonb_array_length(p_rows)>4000 then raise exception 'Assignment harus array 1–4000 baris'; end if;
 insert into public.sjk_assignments(class_code,group_id,module_id,sequence,condition,fault_id,seed,protocol_version)
 select x.class_code,x.group_id,x.module_id,x.sequence,x.condition,x.fault_id,p_seed,(select protocol_version from public.sjk_protocol where id=1)
 from jsonb_to_recordset(p_rows) as x(class_code text,group_id text,module_id integer,sequence text,condition text,fault_id text);
 if exists(select 1 from public.sjk_assignments group by class_code,group_id having count(*)<>4 or count(distinct sequence)<>1) then raise exception 'Setiap kelompok wajib memiliki M12–M15 dan satu sequence yang konsisten'; end if;
 if exists(select 1 from public.sjk_assignments a where not exists(select 1 from public.sjk_participants p where p.class_code=a.class_code and p.group_id=a.group_id and p.consent_status='CONSENTED')) then raise exception 'Ada kelompok assignment tanpa peserta consent'; end if;
 if exists(select 1 from public.sjk_participants p where p.class_code in ('E1','E2') and p.consent_status='CONSENTED' and not exists(select 1 from public.sjk_assignments a where a.class_code=p.class_code and a.group_id=p.group_id)) then raise exception 'Ada kelompok peserta yang belum mendapat assignment'; end if;
 update public.sjk_protocol set seed=p_seed,frozen_at=now(),updated_at=now() where id=1;
 get diagnostics n=row_count;
 select count(*) into n from public.sjk_assignments;
 return n;
end; $$;
create table public.sjk_events (
 event_id text primary key check(event_id ~ '^[A-Z0-9][A-Z0-9._-]{3,99}$'),
 participant_id text not null references public.sjk_participants(participant_id),
 class_code text not null check(class_code in ('E1','E2','BAU')), group_id text not null,
 module_id integer not null check(module_id between 1 and 16),
 task_id text not null check(length(task_id) between 1 and 60),fault_id text not null check(length(fault_id) between 1 and 60),
 sequence text check(sequence in ('S1','S2')),
 condition text not null check(condition in ('Adaptive','Standard','Baseline','CommonAssessment','Transfer')),
 device_id text not null check(device_id ~ '^D-[A-Z0-9_-]{2,30}$'),
 modality text not null check(modality in ('Raspberry Pi','Laptop','VM','Simulation')),
 start_ts timestamptz not null,diagnosis_ts timestamptz,resolution_ts timestamptz,end_ts timestamptz not null,debrief_ts timestamptz,
 window_s integer not null check(window_s between 1 and 3600),
 success boolean not null,diagnosis_first text not null default '' check(length(diagnosis_first)<=3000),diagnosis_correct integer check(diagnosis_correct in (0,1)),
 hint_count integer not null check(hint_count between 0 and 1000),assistant_intervention integer not null check(assistant_intervention between 0 and 1000),
 sa_l1 integer check(sa_l1 between 0 and 2),sa_l2 integer check(sa_l2 between 0 and 2),sa_l3 integer check(sa_l3 between 0 and 2),
 fidelity jsonb not null default '{}', fidelity_deviation text not null default '' check(length(fidelity_deviation)<=3000),
 event_status text not null check(event_status in ('VALID','VALID_NO_TELEMETRY','TECHNICAL_INVALID','PROTOCOL_INVALID')),
 expected_records integer check(expected_records>0),observed_records integer check(observed_records>=0),
 cpu_pct numeric check(cpu_pct between 0 and 100),ram_pct numeric check(ram_pct between 0 and 100),
 rtt_ms numeric check(rtt_ms>=0),packet_loss_pct numeric check(packet_loss_pct between 0 and 100),throughput_mbps numeric check(throughput_mbps>=0),
 latency_p50_ms numeric check(latency_p50_ms>=0),latency_p95_ms numeric check(latency_p95_ms>=0),agent_overhead_pct numeric check(agent_overhead_pct>=0),
 service_state text check(service_state in ('up','down','degraded','not_measured')),
 protocol_version text not null,dashboard_version text not null default 'web-1.0',
 assessor_id uuid not null default auth.uid() references auth.users(id),created_at timestamptz not null default now(),
 supersedes_id text unique references public.sjk_events(event_id),revision_reason text,
 ttr_s numeric generated always as (case when success then extract(epoch from (resolution_ts-start_ts)) else null end) stored,
 followup_s numeric generated always as (case when success then extract(epoch from (resolution_ts-start_ts)) else least(window_s,extract(epoch from (end_ts-start_ts))) end) stored,
 censored boolean generated always as (not success) stored,
 completeness_pct numeric generated always as (case when expected_records>0 then observed_records*100.0/expected_records else null end) stored,
 check(end_ts>=start_ts),check(diagnosis_ts is null or diagnosis_ts between start_ts and end_ts),
 check(debrief_ts is null or debrief_ts>=end_ts),
 check((success and resolution_ts is not null and resolution_ts between start_ts and end_ts and extract(epoch from (resolution_ts-start_ts))<=window_s) or (not success and resolution_ts is null)),
 check(success or event_status not in ('VALID','VALID_NO_TELEMETRY') or extract(epoch from (end_ts-start_ts))>=window_s),
 check(diagnosis_correct is null or (diagnosis_ts is not null and length(trim(diagnosis_first))>0)),
 check((expected_records is null and observed_records is null) or (expected_records is not null and observed_records is not null and observed_records<=expected_records)),
 check(event_status<>'VALID' or (expected_records is not null and observed_records is not null and observed_records*100.0/expected_records>=95)),
 check(event_status not in ('PROTOCOL_INVALID','TECHNICAL_INVALID') or length(trim(fidelity_deviation))>=5),
 check(supersedes_id is null or (supersedes_id<>event_id and length(trim(revision_reason))>=10)),
 check(latency_p50_ms is null or latency_p95_ms is null or latency_p95_ms>=latency_p50_ms)
);
create index sjk_events_participant on public.sjk_events(participant_id);
create index sjk_events_module_condition on public.sjk_events(module_id,condition);
create function public.sjk_check_event() returns trigger language plpgsql security definer set search_path='' as $$
declare p public.sjk_participants; a public.sjk_assignments; v public.sjk_protocol; old_event public.sjk_events; k text;
begin
 select * into p from public.sjk_participants where participant_id=new.participant_id for share;
 select * into v from public.sjk_protocol where id=1;
 if p.participant_id is null or p.consent_status<>'CONSENTED' then raise exception 'Participant belum memberikan consent aktif';end if;
 if not v.research_active then raise exception 'Riset belum diaktifkan oleh admin';end if;
 if new.protocol_version<>v.protocol_version then raise exception 'Versi protokol tidak cocok';end if;
 if new.class_code<>p.class_code or new.group_id<>p.group_id then raise exception 'Kelas/kelompok harus cocok dengan registry';end if;
 if new.module_id between 12 and 15 then
  if p.class_code='BAU' then raise exception 'BAU bukan kelompok eksperimen primer';end if;
  select * into a from public.sjk_assignments where class_code=p.class_code and group_id=p.group_id and module_id=new.module_id;
  if a.group_id is null or new.condition<>a.condition or new.sequence is distinct from a.sequence or new.fault_id<>a.fault_id then raise exception 'Kondisi, sequence, dan fault harus sesuai assignment beku';end if;
  if new.window_s<>600 then raise exception 'Window M12–M15 harus 600 detik';end if;
 elsif new.module_id=16 then
  if new.condition<>'Transfer' or new.window_s<>600 then raise exception 'M16 harus Transfer tanpa cue, window 600 detik';end if;
 elsif new.module_id in (5,10) then
  if new.condition<>'CommonAssessment' then raise exception 'M5/M10 menggunakan CommonAssessment';end if;
 else
  if new.condition<>'Baseline' then raise exception 'Pertemuan ini menggunakan Baseline';end if;
  if new.module_id in (8,11) and new.window_s<>480 then raise exception 'Baseline M8/M11 menggunakan window 480 detik';end if;
 end if;
 if p.class_code='BAU' and new.module_id not in (1,5,10,16) then raise exception 'BAU hanya common baseline/assessment/transfer yang disepakati';end if;
 if new.event_status in ('VALID','VALID_NO_TELEMETRY') and new.module_id>=12 then
  foreach k in array array['fault_verified','condition_concealed','adaptive_no_exact_answer','standard_no_adaptive_cue','window_10min','no_technical_help','first_diagnosis_recorded','sa_complete','fault_restored','telemetry_checked'] loop
   if (new.fidelity->k) is distinct from 'true'::jsonb then raise exception 'Fidelity belum lengkap: %',k;end if;
  end loop;
  if new.assistant_intervention<>0 then raise exception 'Intervensi teknis perlu ditinjau sebagai event invalid';end if;
  if new.condition in ('Standard','Transfer') and new.hint_count<>0 then raise exception 'Standard/Transfer tidak boleh menerima adaptive cue';end if;
  if (new.sa_l1 is null or new.sa_l2 is null or new.sa_l3 is null) and length(trim(new.fidelity_deviation))<5 then raise exception 'Skor SA missing memerlukan alasan';end if;
 end if;
 if new.supersedes_id is not null then
  select * into old_event from public.sjk_events where event_id=new.supersedes_id;
  if old_event.participant_id<>new.participant_id or old_event.module_id<>new.module_id or old_event.task_id<>new.task_id or old_event.fault_id<>new.fault_id then raise exception 'Koreksi harus untuk peserta, modul, task, dan fault yang sama';end if;
 end if;
 new.assessor_id=auth.uid();new.created_at=now();return new;
end;$$;
create trigger sjk_validate_event before insert on public.sjk_events for each row execute function public.sjk_check_event();
create table public.sjk_scoring (
 id uuid primary key default gen_random_uuid(),artifact_id text not null check(length(artifact_id) between 3 and 100),
 participant_id text not null references public.sjk_participants(participant_id),
 assessment text not null check(assessment in ('CA1','CA2','TRANSFER','PROJECT')),
 score numeric not null check(score between 0 and 100),rubric_version text not null,
 notes text not null default '' check(length(notes)<=2000),
 assessor_id uuid not null default auth.uid() references auth.users(id),created_at timestamptz not null default now(),
 unique(artifact_id,assessor_id)
);
create table public.sjk_audit (
 id bigint generated always as identity primary key,table_name text not null,row_id text not null,
 operation text not null,actor_id uuid,at timestamptz not null default now(),old_data jsonb,new_data jsonb
);
create function public.sjk_audit_change() returns trigger language plpgsql security definer set search_path='' as $$
declare before_row jsonb; after_row jsonb;
begin
 if tg_op<>'INSERT' then before_row=to_jsonb(old);end if;
 if tg_op<>'DELETE' then after_row=to_jsonb(new);end if;
 insert into public.sjk_audit(table_name,row_id,operation,actor_id,old_data,new_data)
 values(tg_table_name,coalesce(after_row->>'participant_id',after_row->>'event_id',after_row->>'id',before_row->>'participant_id','1'),tg_op,auth.uid(),before_row,after_row);
 if tg_op='DELETE' then return old;else return new;end if;
end;$$;
create trigger sjk_audit_participants after insert or update or delete on public.sjk_participants for each row execute function public.sjk_audit_change();
create trigger sjk_audit_protocol after update on public.sjk_protocol for each row execute function public.sjk_audit_change();
create trigger sjk_audit_events after insert on public.sjk_events for each row execute function public.sjk_audit_change();
create trigger sjk_audit_scoring after insert on public.sjk_scoring for each row execute function public.sjk_audit_change();
create function public.sjk_protect_participant() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='UPDATE' then
  if new.participant_id<>old.participant_id then raise exception 'participant_id tidak dapat diubah';end if;
  if (new.group_id<>old.group_id or new.class_code<>old.class_code) and exists(select 1 from public.sjk_protocol where frozen_at is not null) then raise exception 'Kelas/kelompok sudah dibekukan';end if;
  new.created_by=old.created_by;new.created_at=old.created_at;
 else
  if exists(select 1 from public.sjk_protocol where frozen_at is not null) and new.class_code<>'BAU' then raise exception 'Roster E1/E2 sudah dibekukan; kelola amendment melalui data steward';end if;
  new.created_by=auth.uid();new.created_at=now();
 end if;
 new.updated_at=now();return new;
end;$$;
create trigger sjk_protect_roster before insert or update on public.sjk_participants for each row execute function public.sjk_protect_participant();
create function public.sjk_protect_protocol() returns trigger language plpgsql set search_path='' as $$
begin
 if old.frozen_at is not null and (new.frozen_at is distinct from old.frozen_at or new.seed<>old.seed or new.protocol_version<>old.protocol_version) then raise exception 'Versi/seed/freeze tidak boleh diubah setelah assignment beku';end if;
 new.updated_at=now();return new;
end;$$;
create trigger sjk_protect_protocol before update on public.sjk_protocol for each row execute function public.sjk_protect_protocol();
-- RLS and grants: no anonymous access, no browser permission to modify staff/assignment/audit.
alter table public.sjk_staff enable row level security;
alter table public.sjk_protocol enable row level security;
alter table public.sjk_participants enable row level security;
alter table public.sjk_assignments enable row level security;
alter table public.sjk_events enable row level security;
alter table public.sjk_scoring enable row level security;
alter table public.sjk_audit enable row level security;
revoke all on public.sjk_staff,public.sjk_protocol,public.sjk_participants,public.sjk_assignments,public.sjk_events,public.sjk_scoring,public.sjk_audit from anon,authenticated;
grant select on public.sjk_staff,public.sjk_protocol,public.sjk_assignments to authenticated;
grant select,insert,update on public.sjk_participants to authenticated;
grant select,insert on public.sjk_events,public.sjk_scoring to authenticated;
grant update(ethics_reference,pilot_ready,research_active,protocol_version) on public.sjk_protocol to authenticated;
grant select on public.sjk_audit to authenticated;
create policy staff_read_self on public.sjk_staff for select to authenticated using(user_id=(select auth.uid()) and active);
create policy protocol_read_staff on public.sjk_protocol for select to authenticated using((select public.sjk_is_staff()));
create policy protocol_update_admin on public.sjk_protocol for update to authenticated using((select public.sjk_is_admin())) with check((select public.sjk_is_admin()));
create policy participants_read_staff on public.sjk_participants for select to authenticated using((select public.sjk_is_staff()));
create policy participants_insert_staff on public.sjk_participants for insert to authenticated with check((select public.sjk_is_staff()) and created_by=(select auth.uid()));
create policy participants_update_staff on public.sjk_participants for update to authenticated using((select public.sjk_is_staff())) with check((select public.sjk_is_staff()));
create policy assignments_read_staff on public.sjk_assignments for select to authenticated using((select public.sjk_is_staff()));
create policy events_read_staff_consent on public.sjk_events for select to authenticated using((select public.sjk_is_staff()) and exists(select 1 from public.sjk_participants p where p.participant_id=sjk_events.participant_id and p.consent_status='CONSENTED'));
create policy events_insert_staff on public.sjk_events for insert to authenticated with check((select public.sjk_is_staff()) and assessor_id=(select auth.uid()));
-- Independent scorers can read only their own scores; admin reviews paired scoring.
create policy scoring_read_own_or_admin on public.sjk_scoring for select to authenticated using((select public.sjk_is_staff()) and (assessor_id=(select auth.uid()) or (select public.sjk_is_admin())) and exists(select 1 from public.sjk_participants p where p.participant_id=sjk_scoring.participant_id and p.consent_status='CONSENTED'));
create policy scoring_insert_staff on public.sjk_scoring for insert to authenticated with check((select public.sjk_is_staff()) and assessor_id=(select auth.uid()) and exists(select 1 from public.sjk_participants p where p.participant_id=sjk_scoring.participant_id and p.consent_status='CONSENTED') and exists(select 1 from public.sjk_protocol where research_active));
create policy audit_read_admin on public.sjk_audit for select to authenticated using((select public.sjk_is_admin()));
-- Prevent PUBLIC/anonymous execution of privileged routines.
revoke all on function public.sjk_is_staff(),public.sjk_is_admin(),public.sjk_freeze_assignments(jsonb,integer),public.sjk_check_event(),public.sjk_audit_change(),public.sjk_protect_participant(),public.sjk_protect_protocol() from public,anon,authenticated;
grant execute on function public.sjk_is_staff(),public.sjk_is_admin(),public.sjk_freeze_assignments(jsonb,integer) to authenticated;
commit;
