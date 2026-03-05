-- ============================================================================
-- PRESCRIPTIONS TABLES FOR SUPABASE
-- ============================================================================
-- Run this SQL in your Supabase SQL Editor to create the necessary tables
-- for the prescriptions feature.
-- ============================================================================

-- Prescriptions table (doctor-issued prescriptions)
CREATE TABLE IF NOT EXISTS prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES profiles(id),
  medication_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL,
  prescribing_doctor TEXT,
  pharmacy TEXT,
  date_prescribed DATE NOT NULL,
  expiry_date DATE,
  status TEXT DEFAULT 'active',
  refills_remaining INT DEFAULT 0,
  refills_total INT DEFAULT 0,
  instructions TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prescription reminders (scheduled notifications for prescriptions)
CREATE TABLE IF NOT EXISTS prescription_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID REFERENCES prescriptions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  scheduled_time TIME,
  scheduled_datetime TIMESTAMPTZ,
  days TEXT[] DEFAULT '{"Everyday"}',
  is_enabled BOOLEAN DEFAULT true,
  is_taken BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prescription refills (refill tracking)
CREATE TABLE IF NOT EXISTS prescription_refills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID REFERENCES prescriptions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending',
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_refills ENABLE ROW LEVEL SECURITY;

-- Prescriptions policies
CREATE POLICY "Users can view own prescriptions" ON prescriptions FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Users can insert own prescriptions" ON prescriptions FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Users can update own prescriptions" ON prescriptions FOR UPDATE USING (student_id = auth.uid());
CREATE POLICY "Users can delete own prescriptions" ON prescriptions FOR DELETE USING (student_id = auth.uid());

-- Prescription reminders policies
CREATE POLICY "Users can view own prescription reminders" ON prescription_reminders FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Users can insert own prescription reminders" ON prescription_reminders FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Users can update own prescription reminders" ON prescription_reminders FOR UPDATE USING (student_id = auth.uid());
CREATE POLICY "Users can delete own prescription reminders" ON prescription_reminders FOR DELETE USING (student_id = auth.uid());

-- Prescription refills policies
CREATE POLICY "Users can view own refill requests" ON prescription_refills FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Users can insert own refill requests" ON prescription_refills FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Users can update own refill requests" ON prescription_refills FOR UPDATE USING (student_id = auth.uid());
CREATE POLICY "Users can delete own refill requests" ON prescription_refills FOR DELETE USING (student_id = auth.uid());

-- ============================================================================
-- NOTE: The profiles table should already exist. If not, create it:
-- ============================================================================

-- CREATE TABLE IF NOT EXISTS profiles (
--   id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
--   full_name TEXT,
--   email TEXT,
--   role TEXT DEFAULT 'student',
--   created_at TIMESTAMPTZ DEFAULT NOW()
-- );
--
-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (id = auth.uid());
-- CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (id = auth.uid());

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Insert a sample prescription (replace 'YOUR_USER_ID' with an actual user ID)
-- INSERT INTO prescriptions (
--   student_id,
--   medication_name,
--   dosage,
--   frequency,
--   prescribing_doctor,
--   pharmacy,
--   date_prescribed,
--   expiry_date,
--   status,
--   refills_remaining,
--   refills_total,
--   instructions
-- ) VALUES (
--   'YOUR_USER_ID',
--   'Amoxicillin',
--   '500mg',
--   '3 times daily',
--   'Dr. Sarah Johnson',
--   'Campus Pharmacy',
--   CURRENT_DATE,
--   CURRENT_DATE + INTERVAL '30 days',
--   'active',
--   2,
--   3,
--   'Take with food'
-- );
