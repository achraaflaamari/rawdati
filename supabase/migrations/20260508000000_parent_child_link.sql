-- Create child_parents join table
CREATE TABLE IF NOT EXISTS public.child_parents (
    child_id UUID REFERENCES public.children(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (child_id, parent_id)
);

-- Enable RLS
ALTER TABLE public.child_parents ENABLE ROW LEVEL SECURITY;

-- Policies for child_parents
CREATE POLICY "Admins can manage child_parents" ON public.child_parents
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Staff can view child_parents" ON public.child_parents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'staff'
        )
    );

CREATE POLICY "Parents can view their own links" ON public.child_parents
    FOR SELECT USING (parent_id = auth.uid());

-- Migrate data from children.parent_ids to child_parents
DO $$
DECLARE
    child_rec RECORD;
    p_id UUID;
BEGIN
    FOR child_rec IN SELECT id, parent_ids FROM public.children WHERE parent_ids IS NOT NULL AND parent_ids <> '{}' LOOP
        FOREACH p_id IN ARRAY child_rec.parent_ids LOOP
            INSERT INTO public.child_parents (child_id, parent_id)
            VALUES (child_rec.id, p_id)
            ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- Update get_parent_feed to use child_parents
CREATE OR REPLACE FUNCTION get_parent_feed(p_parent_id UUID)
RETURNS TABLE (
    photo_id UUID,
    photo_url TEXT,
    activity_id UUID,
    activity_title TEXT,
    activity_date DATE,
    reactions JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ap.id as photo_id,
        ap.photo_url,
        a.id as activity_id,
        a.title as activity_title,
        a.activity_date,
        COALESCE(
            (SELECT jsonb_object_agg(reaction_type, count)
             FROM (
                SELECT r.reaction_type, count(*) as count
                FROM public.reactions r
                WHERE r.photo_id = ap.id
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

-- Update RLS policies that used children.parent_ids
DROP POLICY IF EXISTS "Parents can view their own children" ON public.children;
CREATE POLICY "Parents can view their own children" ON public.children
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.child_parents
            WHERE child_id = children.id AND parent_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Parents can view photos of their children" ON public.activity_photos;
CREATE POLICY "Parents can view photos of their children" ON public.activity_photos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.photo_assignments pa
            JOIN public.child_parents cp ON pa.child_id = cp.child_id
            WHERE pa.photo_id = activity_photos.id 
            AND cp.parent_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Parents can view assignments" ON public.photo_assignments;
CREATE POLICY "Parents can view assignments" ON public.photo_assignments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.child_parents cp
            WHERE cp.child_id = photo_assignments.child_id
            AND cp.parent_id = auth.uid()
        )
    );
