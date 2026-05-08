-- 1. Create the 'photos' bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage policies for 'photos' bucket
DO $$
BEGIN
    -- Policy for viewing photos
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage' 
        AND policyname = 'Public View Access'
    ) THEN
        CREATE POLICY "Public View Access" ON storage.objects
            FOR SELECT USING (bucket_id = 'photos');
    END IF;

    -- Policy for uploading photos
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage' 
        AND policyname = 'Staff Upload Access'
    ) THEN
        CREATE POLICY "Staff Upload Access" ON storage.objects
            FOR INSERT WITH CHECK (
                bucket_id = 'photos' 
                AND auth.role() = 'authenticated'
            );
    END IF;
END $$;

-- 3. Fix Infinite Recursion in RLS
-- Drop the problematic policies first
DROP POLICY IF EXISTS "Staff can manage assignments for their photos" ON public.photo_assignments;
DROP POLICY IF EXISTS "Parents can view photos of their children" ON public.activity_photos;
DROP POLICY IF EXISTS "Staff can manage assignments" ON public.photo_assignments;
DROP POLICY IF EXISTS "Parents can view assignments" ON public.photo_assignments;

-- Create a security definer function to break the recursion cycle.
CREATE OR REPLACE FUNCTION public.is_photo_owner(p_photo_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.activity_photos ap
        JOIN public.activities a ON ap.activity_id = a.id
        WHERE ap.id = p_photo_id AND a.staff_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-create photo_assignments policies using the safe function or direct lookups
CREATE POLICY "Staff can manage assignments" ON public.photo_assignments
    FOR ALL USING (public.is_photo_owner(photo_id, auth.uid()));

CREATE POLICY "Parents can view assignments" ON public.photo_assignments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.children c
            WHERE c.id = photo_assignments.child_id
            AND auth.uid() = ANY(c.parent_ids)
        )
    );

-- 5. Fix activity_photos Parent policy to be safe
CREATE POLICY "Parents can view photos of their children" ON public.activity_photos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.photo_assignments pa
            JOIN public.children c ON pa.child_id = c.id
            WHERE pa.photo_id = activity_photos.id 
            AND auth.uid() = ANY(c.parent_ids)
        )
    );

-- 6. Ensure Parents can view their children (required for the above policies to work)
DROP POLICY IF EXISTS "Parents can view their own children" ON public.children;
CREATE POLICY "Parents can view their own children" ON public.children
    FOR SELECT USING (auth.uid() = ANY(parent_ids));

-- 7. Add is_blocked if not exists (redundant but safe)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT FALSE;
