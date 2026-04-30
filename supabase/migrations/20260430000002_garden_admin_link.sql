-- Add admin_id to garden_info and link it to profiles
ALTER TABLE public.garden_info 
ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Ensure admin_id is unique if each garden has exactly one admin (and vice versa)
-- For now, let's assume one admin can manage one garden.
ALTER TABLE public.garden_info ADD CONSTRAINT garden_info_admin_id_key UNIQUE (admin_id);

-- Update RLS policies for garden_info to be more specific
DROP POLICY IF EXISTS "Only admins can update garden info" ON public.garden_info;

CREATE POLICY "Admins can manage their own garden info" ON public.garden_info
    FOR ALL USING (
        admin_id = auth.uid()
    );

CREATE POLICY "Everyone can view garden info" ON public.garden_info
    FOR SELECT USING (true);
