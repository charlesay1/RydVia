# Policy source of truth

Executable policies are colocated with schema changes in versioned migrations.
The foundation enables RLS on every exposed table. Users may read their own
identity/role/request records; only admin-backed policies permit administrative
mutations. Ordinary profile changes use a constrained RPC. Client metadata never
grants roles. No anonymous table access, public bucket, or Realtime publication is
created. Profile/role responses must not be cached across users.

Do not apply local migrations remotely until the existing live schema and migration
history have been inspected and reconciled. Use the pgTAP tests against a disposable
local database; they insert synthetic auth users and roll back the transaction.
