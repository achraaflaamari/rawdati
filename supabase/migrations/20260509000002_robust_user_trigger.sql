-- Update handle_new_user to be much more robust and use metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role TEXT;
  v_full_name TEXT;
  v_phone TEXT;
  v_address TEXT;
  v_must_change_password BOOLEAN;
BEGIN
  -- Extract info from metadata, with defaults
  v_role := COALESCE(new.raw_user_meta_data->>'role', 'parent');
  v_full_name := COALESCE(new.raw_user_meta_data->>'full_name', '');
  v_phone := new.raw_user_meta_data->>'phone';
  v_address := new.raw_user_meta_data->>'address';
  
  -- Admin created accounts usually must change password
  v_must_change_password := COALESCE((new.raw_user_meta_data->>'must_change_password')::boolean, true);

  INSERT INTO public.profiles (id, email, role, full_name, phone, address, must_change_password)
  VALUES (
    new.id, 
    new.email, 
    v_role, 
    v_full_name, 
    v_phone, 
    v_address, 
    v_must_change_password
  );
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger is active (in case it was disabled)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
