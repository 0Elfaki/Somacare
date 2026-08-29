-- ============================================================================
-- Fix: PostgrestException 42P17 — "infinite recursion detected in policy for
--      relation profiles"
--
-- Symptom  : Book Appointment and My Appointments both fail to load. Any query
--            that touches public.profiles — directly, or through another
--            table's policy that subqueries it — raises 42P17.
--
-- Cause    : The SELECT policy on public.profiles verified the caller's role
--            with a subquery against profiles itself:
--
--              USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'doctor'
--                     AND role = 'student')
--
--            To evaluate that inner SELECT, Postgres must apply the SELECT
--            policy on profiles — which contains the same subquery. The loop
--            never terminates.
--
-- Fix      : Move the role lookup into a SECURITY DEFINER function. It runs as
--            the function owner, so its internal SELECT bypasses RLS entirely
--            and the loop is broken.
--
-- Safe to re-run: every statement is idempotent.
-- Run in: Supabase Dashboard -> SQL Editor, or `supabase db push`.
-- ============================================================================

-- ── 1. Role lookup helpers (SECURITY DEFINER) ───────────────────────────────

-- Look up any user's role without triggering RLS on profiles.
--
-- NOT granted to authenticated. It takes an arbitrary uuid, so an exposed
-- version would be a role oracle: any student could POST to
-- /rest/v1/rpc/get_user_role with somebody else's id and read their role.
-- Policies call current_user_role() instead, which is SECURITY DEFINER and so
-- reaches this one with the owner's privileges rather than the caller's.
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = user_id LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_user_role(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_user_role(uuid) FROM anon;
REVOKE ALL ON FUNCTION public.get_user_role(uuid) FROM authenticated;

-- The caller's own role. Parameterless, so it cannot be used to probe anyone
-- else. This is the one every policy below calls, and the one earlier
-- migrations already reference by name.
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT public.get_user_role(auth.uid());
$$;

GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated;

-- ── 2. Replace every recursive SELECT policy on profiles ────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Dropped by enumeration, not by name. A recursive policy created under any
-- name we did not anticipate would keep raising 42P17, and the whole point of
-- this migration is that none survives. The comprehensive replacement set is
-- created immediately below.
DO $$
DECLARE
  pol record;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles' AND cmd = 'SELECT'
  LOOP
    RAISE NOTICE 'dropping SELECT policy on profiles: %', pol.policyname;
    EXECUTE format('DROP POLICY %I ON public.profiles', pol.policyname);
  END LOOP;
END $$;

-- Everyone reads their own row.
CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT TO authenticated
  USING (auth.uid() = id);

-- Doctors read student rows — the scope the original policy had. Deliberately
-- NOT "doctors read every row": that would newly expose doctors' and admins'
-- rows to any doctor, which is a widening this bug fix has no reason to make.
CREATE POLICY "Doctors can read student profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (public.current_user_role() = 'doctor' AND role = 'student');

-- Students read doctor rows. Required, and previously missing: Book
-- Appointment runs `from('profiles').select().eq('role','doctor')` as a
-- student. With no policy matching, that query does not error — it returns
-- zero rows, so the screen showed "No doctors available" indefinitely and no
-- exception was ever raised to reveal why.
CREATE POLICY "Students can read doctor profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (role = 'doctor');

-- Admins read everything.
CREATE POLICY "Admins can read all profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (public.current_user_role() = 'admin');

-- Writes stay strictly self-scoped.
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- ── 3. Pin profiles.role against self-service escalation ────────────────────
--
-- The read policies above trust profiles.role, and the UPDATE policy lets a
-- user write every column of their own row. Without this trigger any student
-- could PATCH /rest/v1/profiles?id=eq.<self> with {"role":"admin"} and then
-- read every profile in the table (and write to products).
--
-- Role changes now have to come from a privileged context — the service role
-- and any SECURITY DEFINER function bypass this check.

CREATE OR REPLACE FUNCTION public.prevent_profile_role_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role
     AND auth.uid() IS NOT NULL
     AND auth.uid() = OLD.id THEN
    NEW.role := OLD.role;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pin_profile_role ON public.profiles;
CREATE TRIGGER pin_profile_role
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_role_change();

-- ── 4. Route other tables' role checks through the helper too ───────────────
--
-- These policies live on other tables, so they are not self-recursive. They
-- still evaluated the profiles SELECT policy on every row, which is how the
-- 42P17 error propagated into screens that never query profiles directly.
--
-- NOTE ON NAMES: the SELECT policies here were created as "… can read all …"
-- (create_medical_histories.sql, create_lab_results.sql). Dropping the wrong
-- name is silent — the old recursive policy survives and the new one is added
-- alongside it, and because permissive policies OR together, the per-row
-- subquery keeps running. Both spellings are dropped below.

DO $$
BEGIN
  IF to_regclass('public.medical_histories') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Doctors can read all medical histories" ON public.medical_histories;
    DROP POLICY IF EXISTS "Doctors can view all medical histories" ON public.medical_histories;
    DROP POLICY IF EXISTS "Doctors can insert medical histories"   ON public.medical_histories;
    DROP POLICY IF EXISTS "Doctors can update medical histories"   ON public.medical_histories;
    DROP POLICY IF EXISTS "Doctors can delete medical histories"   ON public.medical_histories;

    EXECUTE $p$
      CREATE POLICY "Doctors can read all medical histories"
        ON public.medical_histories FOR SELECT TO authenticated
        USING (public.current_user_role() = 'doctor')
    $p$;
    EXECUTE $p$
      CREATE POLICY "Doctors can insert medical histories"
        ON public.medical_histories FOR INSERT TO authenticated
        WITH CHECK (public.current_user_role() = 'doctor')
    $p$;
    EXECUTE $p$
      CREATE POLICY "Doctors can update medical histories"
        ON public.medical_histories FOR UPDATE TO authenticated
        USING (public.current_user_role() = 'doctor')
    $p$;
    EXECUTE $p$
      CREATE POLICY "Doctors can delete medical histories"
        ON public.medical_histories FOR DELETE TO authenticated
        USING (public.current_user_role() = 'doctor')
    $p$;
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.lab_results') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Doctors can read all lab results" ON public.lab_results;
    DROP POLICY IF EXISTS "Doctors can view all lab results" ON public.lab_results;
    DROP POLICY IF EXISTS "Doctors can insert lab results"   ON public.lab_results;
    DROP POLICY IF EXISTS "Doctors can update lab results"   ON public.lab_results;
    DROP POLICY IF EXISTS "Doctors can delete lab results"   ON public.lab_results;

    EXECUTE $p$
      CREATE POLICY "Doctors can read all lab results"
        ON public.lab_results FOR SELECT TO authenticated
        USING (public.current_user_role() = 'doctor')
    $p$;
    EXECUTE $p$
      CREATE POLICY "Doctors can insert lab results"
        ON public.lab_results FOR INSERT TO authenticated
        WITH CHECK (public.current_user_role() = 'doctor')
    $p$;
    EXECUTE $p$
      CREATE POLICY "Doctors can update lab results"
        ON public.lab_results FOR UPDATE TO authenticated
        USING (public.current_user_role() = 'doctor')
    $p$;
    EXECUTE $p$
      CREATE POLICY "Doctors can delete lab results"
        ON public.lab_results FOR DELETE TO authenticated
        USING (public.current_user_role() = 'doctor')
    $p$;
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.products') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Admin can insert products" ON public.products;
    DROP POLICY IF EXISTS "Admin can update products" ON public.products;

    EXECUTE $p$
      CREATE POLICY "Admin can insert products"
        ON public.products FOR INSERT TO authenticated
        WITH CHECK (public.current_user_role() = 'admin')
    $p$;
    EXECUTE $p$
      CREATE POLICY "Admin can update products"
        ON public.products FOR UPDATE TO authenticated
        USING (public.current_user_role() = 'admin')
    $p$;
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.prescriptions') IS NOT NULL THEN
    DROP POLICY IF EXISTS "Doctors can insert prescriptions" ON public.prescriptions;
    EXECUTE $p$
      CREATE POLICY "Doctors can insert prescriptions"
        ON public.prescriptions FOR INSERT TO authenticated
        WITH CHECK (public.current_user_role() = 'doctor')
    $p$;
  END IF;
END $$;

-- ── 5. Verify ───────────────────────────────────────────────────────────────
-- After running, no `qual` below should contain a subquery on profiles:
--
--   SELECT policyname, cmd, qual FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'profiles';
