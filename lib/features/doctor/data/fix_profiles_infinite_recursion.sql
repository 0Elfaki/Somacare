-- ============================================================================
-- Fix: PostgreSQL RLS Infinite Recursion (Code 42P17) on profiles table
-- Run this script in your Supabase Dashboard -> SQL Editor
-- ============================================================================

-- 1. Create helper function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = user_id LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_doctor()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'doctor'
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_doctor() TO authenticated, anon;

-- 2. Drop existing recursive / conflicting policies on profiles
DROP POLICY IF EXISTS "Allow user to read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Doctors can view student profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public can view doctor profiles" ON public.profiles;
DROP POLICY IF EXISTS "Students can view doctors" ON public.profiles;

-- 3. Apply non-recursive SELECT policy to profiles
CREATE POLICY "Allow user to read profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  auth.uid() = id 
  OR public.get_user_role(auth.uid()) IN ('doctor', 'admin')
  OR role = 'doctor'
);

-- Ensure users can insert and update their own profiles
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT
WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());
