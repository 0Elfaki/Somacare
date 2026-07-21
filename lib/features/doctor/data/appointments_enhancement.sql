-- ============================================================================
-- APPOINTMENTS ENHANCEMENT - Emergency & Real-time Features
-- ============================================================================
-- Run this SQL in your Supabase SQL Editor
-- ============================================================================

-- ── 1. Add emergency and timing columns ───────────────────────────────────────
ALTER TABLE appointments
  ADD COLUMN IF NOT EXISTS is_emergency BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS ended_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS consultation_type TEXT DEFAULT 'scheduled'; -- 'scheduled' or 'emergency'

-- ── 2. Add 'in_progress' status ─────────────────────────────────────────────
-- The status column already exists, but we need to handle 'in_progress' status

-- ── 3. RLS - Students can see their own appointments ────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'appointments'
      AND policyname = 'Students can view their own appointments'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Students can view their own appointments"
        ON appointments FOR SELECT
        USING (
          student_id = auth.uid()
        )
    $policy$;
  END IF;
END $$;

-- ── 4. RLS - Students can insert their own appointments ───────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'appointments'
      AND policyname = 'Students can create appointments'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Students can create appointments"
        ON appointments FOR INSERT
        WITH CHECK (
          student_id = auth.uid()
        )
    $policy$;
  END IF;
END $$;

-- ── 5. RLS - Students can update their own appointments ───────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'appointments'
      AND policyname = 'Students can update their own appointments'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Students can update their own appointments"
        ON appointments FOR UPDATE
        USING (
          student_id = auth.uid()
        )
    $policy$;
  END IF;
END $$;

-- ── 6. Enable realtime for appointments ───────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE appointments;

-- ── 7. Create index for faster queries ─────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_appointments_student_id ON appointments(student_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
