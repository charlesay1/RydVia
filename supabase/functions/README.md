# Edge Function boundary

No Edge Function is required for the initial phone OTP and identity phase; these
use Supabase Auth plus authorization-aware PostgreSQL RPCs. No function is deployed.
Future dispatch/payment/privileged administration functions must validate JWTs,
authorize server-backed roles, validate input, and keep service credentials in
server-side environment configuration. Never ship privileged keys in clients.
