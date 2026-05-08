-- 1. Refine Profiles RLS
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;

CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
    );

CREATE POLICY "Staff can view all profiles" ON public.profiles
    FOR SELECT USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'staff'
    );

CREATE POLICY "Parents can view staff profiles" ON public.profiles
    FOR SELECT USING (
        role = 'staff' AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'parent'
    );

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);


-- 2. Refine Activities RLS
DROP POLICY IF EXISTS "Staff can manage their own activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can view all activities" ON public.activities;

CREATE POLICY "Staff can manage their own activities" ON public.activities
    FOR ALL USING (staff_id = auth.uid());

CREATE POLICY "Staff can view all activities" ON public.activities
    FOR SELECT USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'staff'
    );

CREATE POLICY "Admins can view all activities" ON public.activities
    FOR SELECT USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
    );

CREATE POLICY "Parents can view activities of their children" ON public.activities
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.activity_photos ap
            JOIN public.photo_assignments pa ON pa.photo_id = ap.id
            JOIN public.child_parents cp ON pa.child_id = cp.child_id
            WHERE ap.activity_id = activities.id
            AND cp.parent_id = auth.uid()
        )
    );


-- 3. Ensure Staff can view all children (useful for assignments)
DROP POLICY IF EXISTS "Staff can view children" ON public.children;
CREATE POLICY "Staff can view all children" ON public.children
    FOR SELECT USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'staff'
    );

-- 4. Fix potential recursion in photo_assignments for parents
-- The current policy is:
-- CREATE POLICY "Parents can view assignments" ON public.photo_assignments
--    FOR SELECT USING (
--        EXISTS (
--            SELECT 1 FROM public.child_parents cp
--            WHERE cp.child_id = photo_assignments.child_id
--            AND cp.parent_id = auth.uid()
--        )
--    );
-- This is already quite safe as it only depends on child_parents.

-- 5. Fix potential recursion in activity_photos for parents
-- The current policy is:
-- CREATE POLICY "Parents can view photos of their children" ON public.activity_photos
--    FOR SELECT USING (
--        EXISTS (
--            SELECT 1 FROM public.photo_assignments pa
--            JOIN public.child_parents cp ON pa.child_id = cp.child_id
--            WHERE pa.photo_id = activity_photos.id 
--            AND cp.parent_id = auth.uid()
--        )
--    );
-- This is also safe.

-- 6. Grant usage to authenticated users on all tables in public schema
-- (Just to be sure, although default usually allows this)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
