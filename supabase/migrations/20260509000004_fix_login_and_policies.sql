-- ==========================================================
-- FIX LOGIN & RLS: avoid recursion, complete policies
-- ==========================================================

-- 1. Fix get_my_role to read from JWT instead of querying profiles
--    This avoids infinite recursion when used inside profiles RLS policies.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent');
END;
$$ LANGUAGE plpgsql STABLE;

-- 2. Server-side user creation (keep for admin usage)
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
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) VALUES (
    new_user_id, v_instance_id, 'authenticated', 'authenticated', p_email,
    crypt(p_password, gen_salt('bf')), NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('role', p_role, 'full_name', p_full_name,
                       'phone', p_phone, 'address', p_address,
                       'must_change_password', true),
    NOW(), NOW()
  );

  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Robust new-user trigger
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
  VALUES (new.id, new.email, v_role, v_full_name, v_phone, v_address, v_must_change_password)
  ON CONFLICT (id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Fix get_parent_feed
CREATE OR REPLACE FUNCTION public.get_parent_feed(p_parent_id UUID)
RETURNS TABLE (
    photo_id UUID, photo_url TEXT, activity_id UUID,
    activity_title TEXT, activity_date DATE, reactions JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ap.id as photo_id, ap.photo_url, a.id as activity_id,
        a.title as activity_title, a.activity_date,
        COALESCE(
            (SELECT jsonb_object_agg(reaction_type, count)
             FROM (
                SELECT r.reaction_type, count(*) as count
                FROM public.reactions r WHERE r.photo_id = ap.id
                GROUP BY r.reaction_type
             ) s
            ), '{}'::jsonb
        ) as reactions
    FROM public.activity_photos ap
    JOIN public.activities a ON ap.activity_id = a.id
    JOIN public.photo_assignments pa ON pa.photo_id = ap.id
    JOIN public.child_parents cp ON pa.child_id = cp.child_id
    WHERE cp.parent_id = p_parent_id
    ORDER BY a.activity_date DESC, a.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================================
-- 5. Drop ALL existing policies (found across all migrations)
-- ==========================================================

-- Dynamically drop every policy on tables we manage (covers any name we missed)
DO $$
DECLARE
  pol record;
  tables text[] := ARRAY[
    'public.profiles',
    'public.children',
    'public.child_parents',
    'public.garden_info',
    'public.activities',
    'public.activity_photos',
    'public.photo_assignments',
    'public.reactions'
  ];
  tbl text;
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    FOR pol IN
      EXECUTE format(
        'SELECT policyname FROM pg_policies WHERE schemaname = %L AND tablename = %L',
        split_part(tbl, '.', 1),
        split_part(tbl, '.', 2)
      )
    LOOP
      EXECUTE format('DROP POLICY IF EXISTS %I ON %s', pol.policyname, tbl);
    END LOOP;
  END LOOP;
END $$;

-- profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Staff can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Parents can view staff profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;

-- children
DROP POLICY IF EXISTS "Admins have full access to children" ON public.children;
DROP POLICY IF EXISTS "Admins can manage all children" ON public.children;
DROP POLICY IF EXISTS "Admins can view all children" ON public.children;
DROP POLICY IF EXISTS "Staff can view children" ON public.children;
DROP POLICY IF EXISTS "Staff can view all children" ON public.children;
DROP POLICY IF EXISTS "Parents can view their own children" ON public.children;

-- child_parents
DROP POLICY IF EXISTS "Admins can manage child_parents" ON public.child_parents;
DROP POLICY IF EXISTS "Staff can view child_parents" ON public.child_parents;
DROP POLICY IF EXISTS "Parents can view their own links" ON public.child_parents;

-- garden_info
DROP POLICY IF EXISTS "Garden info is viewable by everyone." ON public.garden_info;
DROP POLICY IF EXISTS "Only admins can update garden info" ON public.garden_info;
DROP POLICY IF EXISTS "Admins can manage their own garden info" ON public.garden_info;
DROP POLICY IF EXISTS "Everyone can view garden info" ON public.garden_info;
DROP POLICY IF EXISTS "Admins can manage garden info" ON public.garden_info;

-- activities
DROP POLICY IF EXISTS "Staff can manage their own activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can view all activities" ON public.activities;
DROP POLICY IF EXISTS "Staff can view all activities" ON public.activities;
DROP POLICY IF EXISTS "Parents can view activities of their children" ON public.activities;
DROP POLICY IF EXISTS "Admins can manage all activities" ON public.activities;

-- activity_photos
DROP POLICY IF EXISTS "Staff can manage photos for their activities" ON public.activity_photos;
DROP POLICY IF EXISTS "Parents can view photos of their children" ON public.activity_photos;
DROP POLICY IF EXISTS "Admins can manage all photos" ON public.activity_photos;
DROP POLICY IF EXISTS "Staff can manage their own photos" ON public.activity_photos;

-- photo_assignments
DROP POLICY IF EXISTS "Staff can manage assignments for their photos" ON public.photo_assignments;
DROP POLICY IF EXISTS "Staff can manage assignments" ON public.photo_assignments;
DROP POLICY IF EXISTS "Parents can view assignments" ON public.photo_assignments;
DROP POLICY IF EXISTS "Admins can manage all assignments" ON public.photo_assignments;
DROP POLICY IF EXISTS "Staff can manage their own assignments" ON public.photo_assignments;

-- reactions
DROP POLICY IF EXISTS "Parents can manage their own reactions" ON public.reactions;
DROP POLICY IF EXISTS "Everyone can view reactions" ON public.reactions;

-- storage
DROP POLICY IF EXISTS "Public View Access" ON storage.objects;
DROP POLICY IF EXISTS "Staff Upload Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated View Access" ON storage.objects;
DROP POLICY IF EXISTS "Authorized Upload Access" ON storage.objects;
DROP POLICY IF EXISTS "Authorized Delete Access" ON storage.objects;

-- ==========================================================
-- 6. Recreate policies cleanly
-- ==========================================================

-- profiles
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can manage all profiles" ON public.profiles
    FOR ALL USING (public.get_my_role() = 'admin');
CREATE POLICY "Staff can view all profiles" ON public.profiles
    FOR SELECT USING (public.get_my_role() = 'staff');
CREATE POLICY "Parents can view staff profiles" ON public.profiles
    FOR SELECT USING (public.get_my_role() = 'parent' AND role = 'staff');

-- children
CREATE POLICY "Admins can manage all children" ON public.children
    FOR ALL USING (public.get_my_role() = 'admin');
CREATE POLICY "Staff can view all children" ON public.children
    FOR SELECT USING (public.get_my_role() = 'staff');
CREATE POLICY "Parents can view their own children" ON public.children
    FOR SELECT USING (
        public.get_my_role() = 'parent'
        AND EXISTS (
            SELECT 1 FROM public.child_parents
            WHERE child_id = children.id AND parent_id = auth.uid()
        )
    );

-- child_parents
CREATE POLICY "Admins can manage child_parents" ON public.child_parents
    FOR ALL USING (public.get_my_role() = 'admin');
CREATE POLICY "Staff can view child_parents" ON public.child_parents
    FOR SELECT USING (public.get_my_role() = 'staff');
CREATE POLICY "Parents can view their own links" ON public.child_parents
    FOR SELECT USING (parent_id = auth.uid());

-- garden_info
CREATE POLICY "Everyone can view garden info" ON public.garden_info
    FOR SELECT USING (true);
CREATE POLICY "Admins can manage garden info" ON public.garden_info
    FOR ALL USING (public.get_my_role() = 'admin');

-- activities
CREATE POLICY "Admins can manage all activities" ON public.activities
    FOR ALL USING (public.get_my_role() = 'admin');
CREATE POLICY "Staff can manage their own activities" ON public.activities
    FOR ALL USING (public.get_my_role() = 'staff' AND staff_id = auth.uid());
CREATE POLICY "Staff can view all activities" ON public.activities
    FOR SELECT USING (public.get_my_role() = 'staff');
CREATE POLICY "Parents can view activities of their children" ON public.activities
    FOR SELECT USING (
        public.get_my_role() = 'parent'
        AND EXISTS (
            SELECT 1 FROM public.activity_photos ap
            JOIN public.photo_assignments pa ON pa.photo_id = ap.id
            JOIN public.child_parents cp ON pa.child_id = cp.child_id
            WHERE ap.activity_id = activities.id AND cp.parent_id = auth.uid()
        )
    );

-- activity_photos
CREATE POLICY "Admins can manage all photos" ON public.activity_photos
    FOR ALL USING (public.get_my_role() = 'admin');
CREATE POLICY "Staff can manage their own photos" ON public.activity_photos
    FOR ALL USING (
        public.get_my_role() = 'staff'
        AND EXISTS (
            SELECT 1 FROM public.activities
            WHERE id = activity_photos.activity_id AND staff_id = auth.uid()
        )
    );
CREATE POLICY "Parents can view photos of their children" ON public.activity_photos
    FOR SELECT USING (
        public.get_my_role() = 'parent'
        AND EXISTS (
            SELECT 1 FROM public.photo_assignments pa
            JOIN public.child_parents cp ON pa.child_id = cp.child_id
            WHERE pa.photo_id = activity_photos.id AND cp.parent_id = auth.uid()
        )
    );

-- photo_assignments
CREATE POLICY "Admins can manage all assignments" ON public.photo_assignments
    FOR ALL USING (public.get_my_role() = 'admin');
CREATE POLICY "Staff can manage their own assignments" ON public.photo_assignments
    FOR ALL USING (
        public.get_my_role() = 'staff'
        AND public.is_photo_owner(photo_id, auth.uid())
    );
CREATE POLICY "Parents can view assignments" ON public.photo_assignments
    FOR SELECT USING (
        public.get_my_role() = 'parent'
        AND EXISTS (
            SELECT 1 FROM public.child_parents cp
            WHERE cp.child_id = photo_assignments.child_id AND cp.parent_id = auth.uid()
        )
    );

-- reactions
CREATE POLICY "Everyone can view reactions" ON public.reactions
    FOR SELECT USING (true);
CREATE POLICY "Parents can manage their own reactions" ON public.reactions
    FOR ALL USING (public.get_my_role() = 'parent' AND parent_id = auth.uid());

-- ==========================================================
-- 7. Helper functions
-- ==========================================================

CREATE OR REPLACE FUNCTION public.is_photo_owner(p_photo_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.activity_photos ap
        JOIN public.activities a ON ap.activity_id = a.id
        WHERE ap.id = p_photo_id AND a.staff_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.delete_user(user_id UUID)
RETURNS void AS $$
BEGIN
    IF public.get_my_role() IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Accès refusé : Seuls les administrateurs peuvent supprimer des utilisateurs.';
    END IF;
    DELETE FROM auth.users WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.toggle_user_block(user_id UUID, blocked BOOLEAN)
RETURNS void AS $$
BEGIN
    IF public.get_my_role() IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Accès refusé : Seuls les administrateurs peuvent bloquer des utilisateurs.';
    END IF;
    UPDATE public.profiles SET is_blocked = blocked WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================================
-- 8. Storage policies
-- ==========================================================

CREATE POLICY "Authenticated View Access" ON storage.objects
    FOR SELECT USING (bucket_id = 'photos' AND auth.role() = 'authenticated');

CREATE POLICY "Authorized Upload Access" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'photos' AND public.get_my_role() IN ('admin', 'staff')
    );

CREATE POLICY "Authorized Delete Access" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'photos' AND public.get_my_role() IN ('admin', 'staff')
    );

-- ==========================================================
-- 9. Sync trigger for parent_ids backward compatibility
-- ==========================================================

CREATE OR REPLACE FUNCTION public.sync_child_parents()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE public.children
    SET parent_ids = (SELECT ARRAY_AGG(parent_id) FROM public.child_parents WHERE child_id = NEW.child_id)
    WHERE id = NEW.child_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.children
    SET parent_ids = (SELECT ARRAY_AGG(parent_id) FROM public.child_parents WHERE child_id = OLD.child_id)
    WHERE id = OLD.child_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS sync_child_parent_ids ON public.child_parents;
CREATE TRIGGER sync_child_parent_ids
  AFTER INSERT OR UPDATE OR DELETE ON public.child_parents
  FOR EACH ROW EXECUTE FUNCTION public.sync_child_parents();

-- ==========================================================
-- 10. Grants
-- ==========================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO authenticated;
