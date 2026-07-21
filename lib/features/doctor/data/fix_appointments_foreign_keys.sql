-- ============================================================================
-- FIX: Add Foreign Key Relationship for Appointments to Profiles
-- ============================================================================
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- STEP 1: Delete problematic appointments with invalid doctor_id
DELETE FROM appointments 
WHERE doctor_id = '49a286a1-639f-4b3a-94db-a5a126fa68ef';

-- STEP 2: Add student_id column if missing
ALTER TABLE appointments
  ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- STEP 3: Drop existing foreign key constraints (if any) and recreate
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_doctor_id_fkey;
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_student_id_fkey;

-- STEP 4: Add foreign key for doctor_id
ALTER TABLE appointments 
  ADD CONSTRAINT appointments_doctor_id_fkey 
  FOREIGN KEY (doctor_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- STEP 5: Add foreign key for student_id
ALTER TABLE appointments 
  ADD CONSTRAINT appointments_student_id_fkey 
  FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- STEP 6: Enable RLS
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- STEP 7: Create RLS policies
DROP POLICY IF EXISTS "Students can view own appointments" ON appointments;
CREATE POLICY "Students can view own appointments"
  ON appointments FOR SELECT
  USING (student_id = auth.uid());

DROP POLICY IF EXISTS "Doctors can view their appointments" ON appointments;
CREATE POLICY "Doctors can view their appointments"
  ON appointments FOR SELECT
  USING (doctor_id = auth.uid());

-- STEP 8: Refresh schema cache
NOTIFY pgrst, 'reload schema';
