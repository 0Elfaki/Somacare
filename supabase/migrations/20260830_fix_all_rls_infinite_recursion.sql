-- ============================================================================
-- SomaCare Database Migration: Fix PostgreSQL RLS Infinite Recursion (Code 42P17)
-- ============================================================================

-- ── 1. Helper Functions (SECURITY DEFINER to break recursion) ─────────────────

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

CREATE OR REPLACE FUNCTION public.is_student()
RETURNS boolean
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

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_doctor() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_student() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;

-- ── 2. Fix Policies on `profiles` Table ───────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow user to read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Doctors can view student profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public can view doctor profiles" ON public.profiles;
DROP POLICY IF EXISTS "Students can view doctors" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

-- Unified non-recursive SELECT policy:
-- 1. Users can read their own profile
-- 2. Doctors/admins can read student profiles
-- 3. Students can read doctor profiles for appointment booking & discovery
CREATE POLICY "Allow user to read profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  auth.uid() = id 
  OR public.get_user_role(auth.uid()) IN ('doctor', 'admin')
  OR role = 'doctor'
);

-- Users can insert and update their own profile
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ── 3. Fix Policies on `appointments` Table ───────────────────────────────────

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Students can create appointments" ON public.appointments;
DROP POLICY IF EXISTS "Doctors can update appointments" ON public.appointments;
DROP POLICY IF EXISTS "Students can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;

-- Students view their own, doctors view appointments assigned to them or emergencies
CREATE POLICY "Users can view own appointments"
  ON public.appointments FOR SELECT
  USING (
    student_id = auth.uid() 
    OR doctor_id = auth.uid()
    OR (public.is_doctor() AND is_emergency = true)
  );

-- Students can insert appointment requests
CREATE POLICY "Students can create appointments"
  ON public.appointments FOR INSERT
  WITH CHECK (student_id = auth.uid());

-- Doctors and students can update appointments (e.g. status changes, reschedule, cancel)
CREATE POLICY "Users can update own appointments"
  ON public.appointments FOR UPDATE
  USING (
    student_id = auth.uid() 
    OR doctor_id = auth.uid()
    OR (public.is_doctor() AND is_emergency = true)
  );

-- ── 4. Fix Policies on `medical_histories` Table ──────────────────────────────

ALTER TABLE IF EXISTS public.medical_histories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can view own medical histories" ON public.medical_histories;
DROP POLICY IF EXISTS "Doctors can view medical histories" ON public.medical_histories;
DROP POLICY IF EXISTS "Doctors can insert medical histories" ON public.medical_histories;
DROP POLICY IF EXISTS "Doctors can update medical histories" ON public.medical_histories;

CREATE POLICY "Students can view own medical histories"
  ON public.medical_histories FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Doctors can view medical histories"
  ON public.medical_histories FOR SELECT
  USING (public.is_doctor());

CREATE POLICY "Doctors can insert medical histories"
  ON public.medical_histories FOR INSERT
  WITH CHECK (public.is_doctor());

CREATE POLICY "Doctors can update medical histories"
  ON public.medical_histories FOR UPDATE
  USING (public.is_doctor());

-- ── 5. Fix Policies on `lab_results` Table ────────────────────────────────────

ALTER TABLE IF EXISTS public.lab_results ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can view own lab results" ON public.lab_results;
DROP POLICY IF EXISTS "Doctors can view lab results" ON public.lab_results;
DROP POLICY IF EXISTS "Doctors can insert lab results" ON public.lab_results;
DROP POLICY IF EXISTS "Doctors can update lab results" ON public.lab_results;

CREATE POLICY "Students can view own lab results"
  ON public.lab_results FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Doctors can view lab results"
  ON public.lab_results FOR SELECT
  USING (public.is_doctor());

CREATE POLICY "Doctors can insert lab results"
  ON public.lab_results FOR INSERT
  WITH CHECK (public.is_doctor());

CREATE POLICY "Doctors can update lab results"
  ON public.lab_results FOR UPDATE
  USING (public.is_doctor());

-- ── 6. Fix Policies on `doctor_patients` Table ─────────────────────────────────

ALTER TABLE IF EXISTS public.doctor_patients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Doctors can view assigned patients" ON public.doctor_patients;
DROP POLICY IF EXISTS "Doctors can manage assigned patients" ON public.doctor_patients;

CREATE POLICY "Doctors can view assigned patients"
  ON public.doctor_patients FOR SELECT
  USING (doctor_id = auth.uid() OR public.is_doctor());

CREATE POLICY "Doctors can manage assigned patients"
  ON public.doctor_patients FOR ALL
  USING (doctor_id = auth.uid() OR public.is_doctor());
