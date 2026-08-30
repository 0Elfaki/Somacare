-- Fix: infinite recursion detected in policy for relation "profiles" (SQLSTATE 42P17)
-- Go to your Supabase Dashboard -> SQL Editor and run this query.

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_doctor()
RETURNS BOOLEAN
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

CREATE OR REPLACE FUNCTION public.is_student()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'student'
  );
$$;

GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_doctor() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_student() TO authenticated, anon;

-- Replace recursive policies with clean SECURITY DEFINER checks
DROP POLICY IF EXISTS "Doctors can view student profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public can view doctor profiles" ON public.profiles;

CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Doctors can view student profiles"
  ON public.profiles FOR SELECT
  USING (
    public.is_doctor() AND role = 'student'
  );

CREATE POLICY "Public can view doctor profiles"
  ON public.profiles FOR SELECT
  USING (role = 'doctor');
