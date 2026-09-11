-- Jalankan setelah schema.sql pada proyek uji Supabase. Seluruh fixture di-rollback.
-- Membutuhkan pgTAP (aktifkan extension pgtap pada Dashboard Database > Extensions).
begin;
set local search_path=public,extensions;
select no_plan();
select ok(not has_table_privilege('anon','public.sjk_events','select'),'anon cannot read research events');
select ok(not has_table_privilege('anon','public.sjk_events','insert'),'anon cannot insert research events');
select ok(not has_table_privilege('authenticated','public.sjk_staff','insert'),'browser cannot add itself as staff');
select ok(not has_table_privilege('authenticated','public.sjk_events','update'),'original event cannot be overwritten');
select ok(not has_table_privilege('authenticated','public.sjk_events','delete'),'original event cannot be deleted by browser');
select ok(not has_table_privilege('authenticated','public.sjk_assignments','insert'),'assignment writes require guarded RPC');
select ok(not has_column_privilege('authenticated','public.sjk_protocol','frozen_at','update'),'browser cannot fabricate freeze timestamp');
insert into auth.users(id,email) values
 ('10000000-0000-0000-0000-000000000001','sjk-qa-admin@example.invalid'),
 ('10000000-0000-0000-0000-000000000002','sjk-qa-assistant@example.invalid'),
 ('10000000-0000-0000-0000-000000000003','sjk-qa-outsider@example.invalid');
insert into sjk_staff(user_id,display_name,role) values
 ('10000000-0000-0000-0000-000000000001','QA Admin','admin'),
 ('10000000-0000-0000-0000-000000000002','QA Assistant','assistant');
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
select is((select count(*)::integer from public.sjk_protocol),0,'unlisted authenticated user cannot read protocol');
select is((select count(*)::integer from public.sjk_participants),0,'unlisted authenticated user cannot read participants');
select throws_ok($$insert into public.sjk_participants(participant_id,class_code,group_id,consent_status) values('PQA001','E1','G01','CONSENTED')$$,'42501',null,'unlisted account cannot insert participant');
select throws_ok($$select public.sjk_freeze_assignments('[]'::jsonb,20260908)$$,'P0001',null,'outsider cannot freeze');
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
select lives_ok($$insert into public.sjk_participants(participant_id,class_code,group_id,consent_status) values('PQA001','E1','G01','CONSENTED')$$,'listed assistant can register participant');
select is((select count(*)::integer from public.sjk_participants where participant_id='PQA001'),1,'listed assistant can read registered participant');
select is((select count(*)::integer from public.sjk_audit),0,'assistant cannot read administrator audit');
select throws_ok($$select public.sjk_freeze_assignments('[]'::jsonb,20260908)$$,'P0001',null,'assistant cannot freeze assignment');
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
select ok((select count(*)>0 from public.sjk_audit),'admin can read participant audit');
select * from finish();
rollback;
