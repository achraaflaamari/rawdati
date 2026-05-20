-- Fix: Add UPDATE policy for users to update their own profile
-- This allows users to change their must_change_password flag after changing password

-- Add UPDATE policy for users to update their own profile
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Ensure RLS is enabled on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
