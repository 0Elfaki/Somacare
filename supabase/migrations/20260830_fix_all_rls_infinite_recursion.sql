-- ============================================================================
-- SomaCare Database Migration: Fix PostgreSQL RLS Infinite Recursion (Code 42P17)
-- ============================================================================
--
-- ROOT CAUSE (PostgreSQL Error 42P17):
-- When Row Level Security (RLS) policies on `public.profiles` or related tables
-- query `profiles` within their `USING` clause (e.g. `(SELECT role FROM profiles WHERE id = auth.uid()) = 'doctor'`),
-- PostgreSQL evaluates the `profiles` SELECT policy on the inner subquery, which triggers
-- the policy again recursively, causing:
-- "infinite recursion detected in policy for relation profiles" (SQLSTATE 42P17).
--
-- FIX STRATEGY:
-- 1. Define SECURITY DEFINER helper functions (`current_user_role()`, `is_doctor()`, `is_student()`, `is_admin()`).
--    Because `SECURITY DEFINER` functions run with the privileges of the database owner,
--    internal SELECT queries on `profiles` bypass RLS checks, breaking the recursive loop completely.
-- 2. Drop all recursive policies on `profiles`, `appointments`, `medical_histories`, `lab_results`, `doctor_patients`.
-- 3. Re-create clean, optimized, non-recursive RLS policies using these helper functions.
-- ============================================================================

-- ── 1. Helper Functions (SECURITY DEFINER to break recursion) ─────────────────

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

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
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

GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_doctor() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_student() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;

-- ── 2. Fix Policies on `profiles` Table ───────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Doctors can view student profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public can view doctor profiles" ON public.profiles;
DROP POLICY IF EXISTS "Students can view doctors" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

-- Anyone authenticated can view their own profile
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (id = auth.uid());

-- Doctors can view student profiles (uses SECURITY DEFINER helper -> NO recursion)
CREATE POLICY "Doctors can view student profiles"
  ON public.profiles FOR SELECT
  USING (
    public.is_doctor() AND role = 'student'
  );

-- Any authenticated user can view doctor profiles (for booking, messaging, consultations)
CREATE POLICY "Public can view doctor profiles"
  ON public.profiles FOR SELECT
  USING (role = 'doctor');

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
