-- ==========================================================
-- FIX: Synchronise raw_user_meta_data.role avec public.profiles
-- pour TOUS les utilisateurs existants.
-- Sans cela, auth.jwt() -> 'user_metadata' ->> 'role' retourne NULL
-- et COALESCE(...) tombe sur 'parent', même pour les admins.
-- ==========================================================

UPDATE auth.users
SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('role', p.role)
FROM public.profiles p
WHERE auth.users.id = p.id
  AND (raw_user_meta_data ->> 'role' IS NULL OR raw_user_meta_data ->> 'role' IS DISTINCT FROM p.role);

-- Also ensure existing users have the other metadata fields if missing
UPDATE auth.users
SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object(
    'full_name', COALESCE(raw_user_meta_data ->> 'full_name', p.full_name, ''),
    'phone', COALESCE(raw_user_meta_data ->> 'phone', p.phone, ''),
    'address', COALESCE(raw_user_meta_data ->> 'address', p.address, '')
)
FROM public.profiles p
WHERE auth.users.id = p.id;
