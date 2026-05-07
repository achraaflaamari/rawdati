-- Create activities table
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT, -- 'Sport', 'Art', 'Musique', 'Lecture', etc.
    activity_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create activity_photos table
CREATE TABLE IF NOT EXISTS public.activity_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID REFERENCES public.activities(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create photo_assignments table (link children to specific photos)
CREATE TABLE IF NOT EXISTS public.photo_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    photo_id UUID REFERENCES public.activity_photos(id) ON DELETE CASCADE,
    child_id UUID REFERENCES public.children(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(photo_id, child_id)
);

-- Enable RLS
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photo_assignments ENABLE ROW LEVEL SECURITY;

-- Policies for activities
CREATE POLICY "Staff can manage their own activities" ON public.activities
    USING (staff_id = auth.uid());

CREATE POLICY "Admins can view all activities" ON public.activities
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Policies for activity_photos
CREATE POLICY "Staff can manage photos for their activities" ON public.activity_photos
    USING (
        EXISTS (
            SELECT 1 FROM public.activities
            WHERE id = activity_photos.activity_id AND staff_id = auth.uid()
        )
    );

CREATE POLICY "Parents can view photos of their children" ON public.activity_photos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.photo_assignments pa
            JOIN public.children c ON pa.child_id = c.id
            WHERE pa.photo_id = activity_photos.id 
            AND auth.uid() = ANY(c.parent_ids)
        )
    );

-- Policies for photo_assignments
CREATE POLICY "Staff can manage assignments for their photos" ON public.photo_assignments
    USING (
        EXISTS (
            SELECT 1 FROM public.activity_photos ap
            JOIN public.activities a ON ap.activity_id = a.id
            WHERE ap.id = photo_assignments.photo_id AND a.staff_id = auth.uid()
        )
    );
