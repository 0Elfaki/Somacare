-- Fix: infinite recursion detected in policy for relation "profiles"
-- Go to your Supabase Dashboard -> SQL Editor and run this query.
--
-- ROOT CAUSE
-- The "Doctors can view student profiles" policy on public.profiles checks
-- the current user's role with a subquery that selects from profiles itself:
--
--   USING (
--     (SELECT role FROM profiles WHERE id = auth.uid()) = 'doctor'
--     AND role = 'student'
--   )
--
-- Postgres has to apply the SELECT policy on profiles to evaluate that
-- inner subquery too — which requires evaluating the same policy again,
-- forever. This breaks every query that touches profiles, including from
-- other tables' policies that reference it (appointments, doctors list,
-- prescriptions, etc.) — which is why "My Appointments" and "Book
-- Appointment" both fail with the same error.
--
-- FIX
-- Move the role lookup into a SECURITY DEFINER function. Because it runs
-- with the function owner's privileges, its internal SELECT on profiles
-- bypasses RLS entirely, breaking the recursive loop.

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated;

-- Replace the recursive policy with one that uses the helper function.
DROP POLICY IF EXISTS "Doctors can view student profiles" ON public.profiles;

CREATE POLICY "Doctors can view student profiles"
  ON public.profiles FOR SELECT
  USING (
    public.current_user_role() = 'doctor'
    AND role = 'student'
  );

-- Every user should also be able to read their own profile row (needed for
-- login, the dashboard greeting, role checks, etc.) — add this if it's
-- missing, it's a plain non-recursive check so it's always safe.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'profiles' AND policyname = 'Users can view their own profile'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Users can view their own profile"
        ON public.profiles FOR SELECT
        USING (id = auth.uid())
    $policy$;
  END IF;
END $$;
