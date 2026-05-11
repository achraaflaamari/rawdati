-- 1. Helper function to get user role safely (Fixes Infinite Recursion)
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (SELECT role FROM public.profiles WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix RLS Policies for Profiles (Use helper function)
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Staff can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Parents can view staff profiles" ON public.profiles;

CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (public.get_my_role() = 'admin');

CREATE POLICY "Staff can view all profiles" ON public.profiles
    FOR SELECT USING (public.get_my_role() = 'staff');

CREATE POLICY "Parents can view staff profiles" ON public.profiles
    FOR SELECT USING (
        role = 'staff' AND public.get_my_role() = 'parent'
    );

-- 3. Fix RLS Policies for Activities
DROP POLICY IF EXISTS "Staff can view all activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can view all activities" ON public.activities;

CREATE POLICY "Staff can view all activities" ON public.activities
    FOR SELECT USING (public.get_my_role() = 'staff');

CREATE POLICY "Admins can view all activities" ON public.activities
    FOR SELECT USING (public.get_my_role() = 'admin');

-- 4. Fix RLS Policies for Children
DROP POLICY IF EXISTS "Staff can view all children" ON public.children;

CREATE POLICY "Staff can view all children" ON public.children
    FOR SELECT USING (public.get_my_role() = 'staff');

-- 5. Secure Admin Functions (Add role check)
CREATE OR REPLACE FUNCTION public.delete_user(user_id UUID)
RETURNS void AS $$
BEGIN
    IF public.get_my_role() <> 'admin' THEN
        RAISE EXCEPTION 'Accès refusé : Seuls les administrateurs peuvent supprimer des utilisateurs.';
    END IF;
    DELETE FROM auth.users WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.toggle_user_block(user_id UUID, blocked BOOLEAN)
RETURNS void AS $$
BEGIN
    IF public.get_my_role() <> 'admin' THEN
        RAISE EXCEPTION 'Accès refusé : Seuls les administrateurs peuvent bloquer des utilisateurs.';
    END IF;
    UPDATE public.profiles SET is_blocked = blocked WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Enable the New User Trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
