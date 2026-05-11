-- Seed data for testing

-- Ensure pgcrypto is available (usually in extensions schema in Supabase)
CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;

-- 1. Create Users in auth.users
-- Admin
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES 
('d1111111-1111-1111-1111-111111111111', 'admin@rawdati.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"role": "admin", "full_name": "Admin Rawdati"}'::jsonb, now(), now(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- Staff
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES 
('d2222222-2222-2222-2222-222222222222', 'staff1@rawdati.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"role": "staff", "full_name": "Sarah Staff", "phone": "12345678"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
('d3333333-3333-3333-3333-333333333333', 'staff2@rawdati.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"role": "staff", "full_name": "Ahmed Staff", "phone": "87654321"}'::jsonb, now(), now(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- Parents
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES 
('d4444444-4444-4444-4444-444444444444', 'parent1@gmail.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"role": "parent", "full_name": "John Doe", "phone": "55555555"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
('d5555555-5555-5555-5555-555555555555', 'parent2@gmail.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"role": "parent", "full_name": "Jane Smith", "phone": "44444444"}'::jsonb, now(), now(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- 2. Garden Info
-- Note: The trigger handle_new_user should have created the profiles by now.
INSERT INTO public.garden_info (name, email, phone, address, working_hours, admin_id)
VALUES ('Rawdati El-Amal', 'contact@rawdati.com', '71000000', 'Tunis, Tunisie', '08:00 - 17:00', 'd1111111-1111-1111-1111-111111111111')
ON CONFLICT (admin_id) DO NOTHING;

-- 3. Children
INSERT INTO public.children (id, first_name, last_name, group_name, birth_date, parent_ids)
VALUES 
('c1111111-1111-1111-1111-111111111111', 'Adam', 'Doe', 'Les Papillons', '2020-05-15', ARRAY['d4444444-4444-4444-4444-444444444444']::uuid[]),
('c2222222-2222-2222-2222-222222222222', 'Lina', 'Doe', 'Les Papillons', '2021-08-20', ARRAY['d4444444-4444-4444-4444-444444444444']::uuid[]),
('c3333333-3333-3333-3333-333333333333', 'Omar', 'Smith', 'Les Abeilles', '2019-12-10', ARRAY['d5555555-5555-5555-5555-555555555555']::uuid[])
ON CONFLICT (id) DO NOTHING;

-- 4. Child-Parent Links
INSERT INTO public.child_parents (child_id, parent_id)
VALUES 
('c1111111-1111-1111-1111-111111111111', 'd4444444-4444-4444-4444-444444444444'),
('c2222222-2222-2222-2222-222222222222', 'd4444444-4444-4444-4444-444444444444'),
('c3333333-3333-3333-3333-333333333333', 'd5555555-5555-5555-5555-555555555555')
ON CONFLICT (child_id, parent_id) DO NOTHING;

-- 5. Activities
INSERT INTO public.activities (staff_id, title, description, category, activity_date)
VALUES 
('d2222222-2222-2222-2222-222222222222', 'Peinture au doigt', 'Les enfants ont exploré les couleurs avec leurs mains.', 'Artistique', '2026-05-10'),
('d3333333-3333-3333-3333-333333333333', 'Sortie au jardin', 'Découverte des plantes et des insectes.', 'Nature', '2026-05-11');
