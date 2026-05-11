-- ==========================================================
-- FIX: Récursion infinie entre activities et activity_photos
-- Cause: les policies font des sous-SELECTs croisés sur des
-- tables qui ont toutes RLS activé.
-- Solution: extraire les sous-SELECTs dans des fonctions
-- SECURITY DEFINER (bypass RLS).
-- ==========================================================

-- 1. Function to check if a user is the owner of an activity (for staff)
CREATE OR REPLACE FUNCTION public.is_staff_activity_owner(p_activity_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.activities
        WHERE id = p_activity_id AND staff_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to check if an activity concerns a parent's child
CREATE OR REPLACE FUNCTION public.is_parent_activity(p_activity_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.activity_photos ap
        JOIN public.photo_assignments pa ON pa.photo_id = ap.id
        JOIN public.child_parents cp ON pa.child_id = cp.child_id
        WHERE ap.activity_id = p_activity_id AND cp.parent_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Recreate the problematic policies using the functions above
DROP POLICY IF EXISTS "Staff can manage their own photos" ON public.activity_photos;
DROP POLICY IF EXISTS "Parents can view activities of their children" ON public.activities;

CREATE POLICY "Staff can manage their own photos" ON public.activity_photos
    FOR ALL USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'staff'
        AND public.is_staff_activity_owner(activity_id, auth.uid())
    );

CREATE POLICY "Parents can view activities of their children" ON public.activities
    FOR SELECT USING (
        COALESCE(auth.jwt() -> 'user_metadata' ->> 'role', 'parent') = 'parent'
        AND public.is_parent_activity(id)
    );
