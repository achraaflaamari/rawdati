-- ==========================================================
-- FINAL PERMISSIONS & STORAGE SECURITY
-- ==========================================================

-- 1. Ensure Admin has full CRUD on Profiles
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
CREATE POLICY "Admins can manage all profiles" ON public.profiles
    FOR ALL USING (public.get_my_role() = 'admin');

-- 2. Ensure Admin has full CRUD on Children
DROP POLICY IF EXISTS "Admins can manage all children" ON public.children;
CREATE POLICY "Admins can manage all children" ON public.children
    FOR ALL USING (public.get_my_role() = 'admin');

-- 3. Ensure Admin has full CRUD on child_parents links
DROP POLICY IF EXISTS "Admins can manage child_parents" ON public.child_parents;
CREATE POLICY "Admins can manage child_parents" ON public.child_parents
    FOR ALL USING (public.get_my_role() = 'admin');

-- 4. Admin full moderation on content
DROP POLICY IF EXISTS "Admins can manage all photos" ON public.activity_photos;
DROP POLICY IF EXISTS "Admins can manage all assignments" ON public.photo_assignments;

CREATE POLICY "Admins can manage all photos" ON public.activity_photos FOR ALL USING (public.get_my_role() = 'admin');
CREATE POLICY "Admins can manage all assignments" ON public.photo_assignments FOR ALL USING (public.get_my_role() = 'admin');

-- 5. Refine Storage Policies (Bucket: photos)
DROP POLICY IF EXISTS "Public View Access" ON storage.objects;
DROP POLICY IF EXISTS "Staff Upload Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated View Access" ON storage.objects;
DROP POLICY IF EXISTS "Authorized Upload Access" ON storage.objects;
DROP POLICY IF EXISTS "Authorized Delete Access" ON storage.objects;

-- View access for authenticated users
CREATE POLICY "Authenticated View Access" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'photos' AND auth.role() = 'authenticated'
    );

-- Upload & Delete: Restricted to Admin and Staff
CREATE POLICY "Authorized Upload Access" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'photos' AND (public.get_my_role() IN ('admin', 'staff'))
    );

CREATE POLICY "Authorized Delete Access" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'photos' AND (public.get_my_role() IN ('admin', 'staff'))
    );

-- 6. Refine Parent visibility for Staff profiles (required for feed names)
DROP POLICY IF EXISTS "Parents can view staff profiles" ON public.profiles;
CREATE POLICY "Parents can view staff profiles" ON public.profiles
    FOR SELECT USING (
        (id = auth.uid()) OR 
        (role = 'staff' AND public.get_my_role() = 'parent')
    );
