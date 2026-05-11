-- ==========================================================
-- FIX: remplace get_my_role() par lecture directe JWT
-- dans TOUTES les RLS policies pour eliminer toute recursion.
-- ==========================================================

-- 1. Drop ALL existing policies dynamically
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

-- 2. Recreate get_my_role for backward compatibility of functions (not used in policies)
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent');
END;
$$ LANGUAGE plpgsql STABLE;

-- 3. Recreate all policies using DIRECT JWT read (NO function call)
--    This guarantees zero recursion.

-- profiles
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can manage all profiles" ON public.profiles
    FOR ALL USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'admin');
CREATE POLICY "Staff can view all profiles" ON public.profiles
    FOR SELECT USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'staff');
CREATE POLICY "Parents can view staff profiles" ON public.profiles
    FOR SELECT USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'parent' AND role = 'staff'
    );

-- children
CREATE POLICY "Admins can manage all children" ON public.children
    FOR ALL USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'admin');
CREATE POLICY "Staff can view all children" ON public.children
    FOR SELECT USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'staff');
CREATE POLICY "Parents can view their own children" ON public.children
    FOR SELECT USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'parent'
        AND EXISTS (
            SELECT 1 FROM public.child_parents
            WHERE child_id = children.id AND parent_id = auth.uid()
        )
    );

-- child_parents
CREATE POLICY "Admins can manage child_parents" ON public.child_parents
    FOR ALL USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'admin');
CREATE POLICY "Staff can view child_parents" ON public.child_parents
    FOR SELECT USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'staff');
CREATE POLICY "Parents can view their own links" ON public.child_parents
    FOR SELECT USING (parent_id = auth.uid());

-- garden_info
CREATE POLICY "Everyone can view garden info" ON public.garden_info
    FOR SELECT USING (true);
CREATE POLICY "Admins can manage garden info" ON public.garden_info
    FOR ALL USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'admin');

-- activities
CREATE POLICY "Admins can manage all activities" ON public.activities
    FOR ALL USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'admin');
CREATE POLICY "Staff can manage their own activities" ON public.activities
    FOR ALL USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'staff'
        AND staff_id = auth.uid()
    );
CREATE POLICY "Staff can view all activities" ON public.activities
    FOR SELECT USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'staff');
CREATE POLICY "Parents can view activities of their children" ON public.activities
    FOR SELECT USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'parent'
        AND EXISTS (
            SELECT 1 FROM public.activity_photos ap
            JOIN public.photo_assignments pa ON pa.photo_id = ap.id
            JOIN public.child_parents cp ON pa.child_id = cp.child_id
            WHERE ap.activity_id = activities.id AND cp.parent_id = auth.uid()
        )
    );

-- activity_photos
CREATE POLICY "Admins can manage all photos" ON public.activity_photos
    FOR ALL USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'admin');
CREATE POLICY "Staff can manage their own photos" ON public.activity_photos
    FOR ALL USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'staff'
        AND EXISTS (
            SELECT 1 FROM public.activities
            WHERE id = activity_photos.activity_id AND staff_id = auth.uid()
        )
    );
CREATE POLICY "Parents can view photos of their children" ON public.activity_photos
    FOR SELECT USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'parent'
        AND EXISTS (
            SELECT 1 FROM public.photo_assignments pa
            JOIN public.child_parents cp ON pa.child_id = cp.child_id
            WHERE pa.photo_id = activity_photos.id AND cp.parent_id = auth.uid()
        )
    );

-- photo_assignments
CREATE POLICY "Admins can manage all assignments" ON public.photo_assignments
    FOR ALL USING (COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'admin');
CREATE POLICY "Staff can manage their own assignments" ON public.photo_assignments
    FOR ALL USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'staff'
        AND public.is_photo_owner(photo_id, auth.uid())
    );
CREATE POLICY "Parents can view assignments" ON public.photo_assignments
    FOR SELECT USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'parent'
        AND EXISTS (
            SELECT 1 FROM public.child_parents cp
            WHERE cp.child_id = photo_assignments.child_id AND cp.parent_id = auth.uid()
        )
    );

-- reactions
CREATE POLICY "Everyone can view reactions" ON public.reactions
    FOR SELECT USING (true);
CREATE POLICY "Parents can manage their own reactions" ON public.reactions
    FOR ALL USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'parent'
        AND parent_id = auth.uid()
    );

-- 4. Keep helper functions (SECURITY DEFINER = safe, bypasses RLS)
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
    IF COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Accès refusé : Seuls les administrateurs peuvent supprimer des utilisateurs.';
    END IF;
    DELETE FROM auth.users WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.toggle_user_block(user_id UUID, blocked BOOLEAN)
RETURNS void AS $$
BEGIN
    IF COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Accès refusé : Seuls les administrateurs peuvent bloquer des utilisateurs.';
    END IF;
    UPDATE public.profiles SET is_blocked = blocked WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Storage policies (direct JWT read)
DROP POLICY IF EXISTS "Authenticated View Access" ON storage.objects;
DROP POLICY IF EXISTS "Authorized Upload Access" ON storage.objects;
DROP POLICY IF EXISTS "Authorized Delete Access" ON storage.objects;

CREATE POLICY "Authenticated View Access" ON storage.objects
    FOR SELECT USING (bucket_id = 'photos' AND auth.role() = 'authenticated');

CREATE POLICY "Authorized Upload Access" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'photos'
        AND COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') IN ('admin', 'staff')
    );

CREATE POLICY "Authorized Delete Access" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'photos'
        AND COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') IN ('admin', 'staff')
    );
