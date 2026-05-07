-- Create reactions table
CREATE TABLE IF NOT EXISTS public.reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    photo_id UUID REFERENCES public.activity_photos(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    reaction_type TEXT NOT NULL, -- '❤️', '😊', '😂', '😮', '👏'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(photo_id, parent_id)
);

-- Enable RLS
ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;

-- Policies for reactions
CREATE POLICY "Parents can manage their own reactions" ON public.reactions
    USING (parent_id = auth.uid());

CREATE POLICY "Everyone can view reactions" ON public.reactions
    FOR SELECT USING (true);

-- Function to get photos for a parent's children
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
    JOIN public.children c ON pa.child_id = c.id
    WHERE p_parent_id = ANY(c.parent_ids)
    ORDER BY a.activity_date DESC, a.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
