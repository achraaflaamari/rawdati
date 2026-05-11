-- ==========================================================
-- FIX: Login 500 "Database error querying schema"
-- Cause: missing token columns in auth.users when created
-- via SQL function (confirmation_token, email_change, etc.)
-- GoTrue cannot scan NULL into string fields.
-- ==========================================================

-- 1. Fix existing users: set NULL token columns to empty string
UPDATE auth.users
SET
    confirmation_token = COALESCE(confirmation_token, ''),
    email_change = COALESCE(email_change, ''),
    email_change_token_new = COALESCE(email_change_token_new, ''),
    recovery_token = COALESCE(recovery_token, '')
WHERE
    confirmation_token IS NULL
    OR email_change IS NULL
    OR email_change_token_new IS NULL
    OR recovery_token IS NULL;

-- 2. Fix create_user_by_admin to always include these columns
CREATE OR REPLACE FUNCTION public.create_user_by_admin(
  p_email TEXT,
  p_password TEXT,
  p_role TEXT,
  p_full_name TEXT,
  p_phone TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  new_user_id UUID;
  v_instance_id UUID;
  v_admin_role TEXT;
BEGIN
  SELECT role INTO v_admin_role FROM public.profiles WHERE id = auth.uid();
  IF v_admin_role IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Accès refusé : seuls les administrateurs peuvent créer des utilisateurs.';
  END IF;

  SELECT instance_id INTO v_instance_id FROM auth.users LIMIT 1;
  IF v_instance_id IS NULL THEN
    v_instance_id := '00000000-0000-0000-0000-000000000000'::UUID;
  END IF;

  new_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    confirmation_token, email_change, email_change_token_new, recovery_token,
    created_at, updated_at
  ) VALUES (
    new_user_id, v_instance_id, 'authenticated', 'authenticated', p_email,
    crypt(p_password, gen_salt('bf')), NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('role', p_role, 'full_name', p_full_name,
                         'phone', p_phone, 'address', p_address,
                         'must_change_password', true),
    '', '', '', '',  -- explicitly set token columns to empty string
    NOW(), NOW()
  );

  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Also fix handle_new_user trigger for client-side signUp fallback
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role TEXT;
  v_full_name TEXT;
  v_phone TEXT;
  v_address TEXT;
  v_must_change_password BOOLEAN;
BEGIN
  v_role := COALESCE(new.raw_user_meta_data->>'role', 'parent');
  v_full_name := COALESCE(new.raw_user_meta_data->>'full_name', '');
  v_phone := new.raw_user_meta_data->>'phone';
  v_address := new.raw_user_meta_data->>'address';
  v_must_change_password := COALESCE((new.raw_user_meta_data->>'must_change_password')::boolean, true);

  INSERT INTO public.profiles (id, email, role, full_name, phone, address, must_change_password)
  VALUES (
    new.id,
    new.email,
    v_role,
    v_full_name,
    v_phone,
    v_address,
    v_must_change_password
  );

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
