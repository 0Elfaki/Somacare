-- ============================================================================
-- FIX: doctor_patients RLS Policy Issue
-- ============================================================================
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- The trigger runs as SYSTEM (not as authenticated user), so we need to 
-- disable RLS for the trigger or use SECURITY DEFINER

-- Option 1: Drop the trigger and recreate it with proper handling
DROP TRIGGER IF EXISTS on_appointment_created ON appointments;

-- Option 2: Recreate the function with SECURITY DEFINER to run as superuser
CREATE OR REPLACE FUNCTION create_doctor_patient_relationship()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO doctor_patients (doctor_id, student_id)
  VALUES (NEW.doctor_id, NEW.student_id)
  ON CONFLICT (doctor_id, student_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_appointment_created
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION create_doctor_patient_relationship();

-- Also allow anonymous/service role to read doctor_patients for app functionality
-- Add a policy that allows authenticated users to read
DROP POLICY IF EXISTS "Authenticated users can read doctor_patients" ON doctor_patients;
CREATE POLICY "Authenticated users can read doctor_patients" ON doctor_patients
  FOR SELECT
  TO authenticated
  USING (true);
