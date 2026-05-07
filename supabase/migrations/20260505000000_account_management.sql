-- Add is_blocked column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT FALSE;

-- Function to delete a user (admin only)
CREATE OR REPLACE FUNCTION public.delete_user(user_id UUID)
RETURNS void AS $$
BEGIN
    DELETE FROM auth.users WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to toggle user block status (admin only)
CREATE OR REPLACE FUNCTION public.toggle_user_block(user_id UUID, blocked BOOLEAN)
RETURNS void AS $$
BEGIN
    UPDATE public.profiles SET is_blocked = blocked WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
