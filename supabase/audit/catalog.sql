-- Metadata only: no user rows, secret values, function bodies, or policy literals.
select pg_catalog.jsonb_build_object(
  'schemas', (select coalesce(pg_catalog.jsonb_agg(n.nspname order by n.nspname),'[]'::jsonb)
    from pg_catalog.pg_namespace n where n.nspname not like 'pg_%' and n.nspname <> 'information_schema'),
  'relations', (select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'schema',n.nspname,'name',c.relname,'kind',c.relkind,'rls',c.relrowsecurity,'forceRls',c.relforcerowsecurity,
      'securityInvoker',coalesce(c.reloptions @> array['security_invoker=true'],false),
      'viewDefinitionHash',case when c.relkind in ('v','m') then pg_catalog.md5(pg_catalog.pg_get_viewdef(c.oid,true)) else null end,
      'estimatedRows',c.reltuples,
      'columns',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('name',a.attname,'type',pg_catalog.format_type(a.atttypid,a.atttypmod),'notNull',a.attnotnull,'hasDefault',a.atthasdef,
          'defaultHash',(select pg_catalog.md5(pg_catalog.pg_get_expr(d.adbin,d.adrelid)) from pg_catalog.pg_attrdef d where d.adrelid=a.attrelid and d.adnum=a.attnum)) order by a.attnum),'[]'::jsonb)
        from pg_catalog.pg_attribute a where a.attrelid=c.oid and a.attnum>0 and not a.attisdropped)
    ) order by n.nspname,c.relname),'[]'::jsonb)
    from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
    where n.nspname not like 'pg_%' and n.nspname <> 'information_schema' and c.relkind in ('r','p','v','m','f')),
  'constraints',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('schema',n.nspname,'table',c.relname,'name',k.conname,'type',k.contype,'definitionHash',pg_catalog.md5(pg_catalog.pg_get_constraintdef(k.oid))) order by n.nspname,c.relname,k.conname),'[]'::jsonb)
    from pg_catalog.pg_constraint k join pg_catalog.pg_class c on c.oid=k.conrelid join pg_catalog.pg_namespace n on n.oid=c.relnamespace
    where n.nspname not like 'pg_%' and n.nspname <> 'information_schema'),
  'policies',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('schema',p.schemaname,'table',p.tablename,'name',p.policyname,'roles',p.roles,'command',p.cmd,'permissive',p.permissive,'usingHash',pg_catalog.md5(coalesce(p.qual,'')),'checkHash',pg_catalog.md5(coalesce(p.with_check,''))) order by p.schemaname,p.tablename,p.policyname),'[]'::jsonb)
    from pg_catalog.pg_policies p),
  'functions',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('schema',n.nspname,'name',p.proname,'arguments',pg_catalog.pg_get_function_identity_arguments(p.oid),'owner',pg_catalog.pg_get_userbyid(p.proowner),'securityDefiner',p.prosecdef,'definitionHash',pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))) order by n.nspname,p.proname,p.oid),'[]'::jsonb)
    from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','private') and p.prokind='f'),
  'triggers',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('schema',n.nspname,'table',c.relname,'name',t.tgname,'definitionHash',pg_catalog.md5(pg_catalog.pg_get_triggerdef(t.oid))) order by n.nspname,c.relname,t.tgname),'[]'::jsonb)
    from pg_catalog.pg_trigger t join pg_catalog.pg_class c on c.oid=t.tgrelid join pg_catalog.pg_namespace n on n.oid=c.relnamespace where not t.tgisinternal and n.nspname in ('auth','public','private')),
  'roles',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('name',r.rolname,'canLogin',r.rolcanlogin,'superuser',r.rolsuper,'bypassRls',r.rolbypassrls) order by r.rolname),'[]'::jsonb) from pg_catalog.pg_roles r),
  'grants',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('schema',g.table_schema,'table',g.table_name,'role',g.grantee,'privilege',g.privilege_type) order by g.table_schema,g.table_name,g.grantee,g.privilege_type),'[]'::jsonb)
    from information_schema.role_table_grants g where g.table_schema in ('public','private','storage') and g.grantee in ('anon','authenticated','service_role','PUBLIC')),
  'functionGrants',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('schema',n.nspname,'name',p.proname,'arguments',pg_catalog.pg_get_function_identity_arguments(p.oid),'role',case when a.grantee=0 then 'PUBLIC' else pg_catalog.pg_get_userbyid(a.grantee) end,'privilege',a.privilege_type) order by n.nspname,p.proname,a.grantee),'[]'::jsonb)
    from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    cross join lateral pg_catalog.aclexplode(coalesce(p.proacl,pg_catalog.acldefault('f',p.proowner))) a
    where n.nspname in ('public','private') and p.prokind='f' and (a.grantee=0 or pg_catalog.pg_get_userbyid(a.grantee) in ('anon','authenticated','service_role'))),
  'publications',(select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('name',p.pubname,'schema',p.schemaname,'table',p.tablename) order by p.pubname,p.schemaname,p.tablename),'[]'::jsonb) from pg_catalog.pg_publication_tables p)
) as inventory;
