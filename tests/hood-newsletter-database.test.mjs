import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
test('newsletter signup validates anonymous consent, preserves privacy and supports unsubscribe',async()=>{
 const db=new PGlite();
 await db.exec(`create role anon;create role authenticated;create schema private;grant usage on schema private to anon,authenticated;create function private.is_admin() returns boolean language sql as $$select current_setting('test.admin',true)='true'$$;create table public.products(id uuid primary key);`);
 await db.exec(readFileSync(new URL('../supabase/updates/hood_newsletter_signup.sql',import.meta.url),'utf8'));
 await db.exec(`set role anon;select public.subscribe_newsletter('  TEST-NEWSLETTER@example.com  ');select public.subscribe_newsletter('test-newsletter@example.com');reset role;`);
 let rows=(await db.query('select * from public.newsletter_subscribers')).rows;assert.equal(rows.length,1);assert.equal(rows[0].email,'test-newsletter@example.com');assert.equal(rows[0].active,true);
 await db.exec('set role anon');await assert.rejects(db.query('select * from public.newsletter_subscribers'),/permission denied/);await assert.rejects(db.query("select public.subscribe_newsletter('invalid')"),/valid email/);
 await db.query('select public.unsubscribe_newsletter($1)',[rows[0].unsubscribe_token]);await db.exec('reset role');
 assert.equal((await db.query('select active from public.newsletter_subscribers')).rows[0].active,false);
 await db.exec(`set role anon;select public.subscribe_newsletter('test-newsletter@example.com');reset role;`);
 assert.equal((await db.query('select active from public.newsletter_subscribers')).rows[0].active,true);
 await db.exec(`set role authenticated;select set_config('test.admin','false',false)`);assert.equal((await db.query('select * from public.newsletter_subscribers')).rows.length,0);
 await db.exec(`select set_config('test.admin','true',false)`);assert.equal((await db.query('select * from public.newsletter_subscribers')).rows.length,1);
 await db.close();
});
