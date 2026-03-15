-- Dev admin account — recreated automatically after every `make db-reset`
-- Credentials: admin@dev.local / admin1234
do $$
declare
  v_user_id uuid := '00000000-0000-0000-0000-000000000001';
  v_email   text := 'admin@dev.local';
begin
  insert into auth.users (
    id, instance_id, aud, role,
    email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, is_sso_user, is_anonymous,
    created_at, updated_at
  ) values (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    v_email,
    extensions.crypt('admin1234', extensions.gen_salt('bf', 10)),
    now(),
    '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"username": "DevAdmin", "role": "admin"}'::jsonb,
    false, false, false,
    now(), now()
  ) on conflict (id) do nothing;

  insert into auth.identities (
    user_id, provider_id, provider, identity_data,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_user_id, v_email, 'email',
    jsonb_build_object('sub', v_user_id::text, 'email', v_email),
    now(), now(), now()
  ) on conflict (provider_id, provider) do nothing;
end $$;
