import { readFile, readdir } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';

export async function localCatalog(root) {
  const db=new PGlite();
  try {
    await db.exec(`create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls;
      create schema auth; grant usage on schema auth to authenticated;
      create table auth.users(id uuid primary key);
      create function auth.uid() returns uuid language sql stable as $$ select (nullif(current_setting('request.jwt.claims',true),'')::jsonb ->> 'sub')::uuid; $$;
      grant execute on function auth.uid() to authenticated;`);
    const files=(await readdir(new URL('supabase/migrations/',root))).filter(file=>file.endsWith('.sql')).sort();
    for(const file of files) await db.exec(await readFile(new URL(`supabase/migrations/${file}`,root),'utf8'));
    const result=await db.query(await readFile(new URL('supabase/audit/catalog.sql',root),'utf8'));
    return {migrations:files.map(file=>file.split('_')[0]),inventory:result.rows[0].inventory};
  } finally {await db.close();}
}
