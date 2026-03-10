-- ============================================================================
-- Add missing columns to appointments table for doctor portal
-- ============================================================================

-- Add fee column for tracking consultation fees
ALTER TABLE appointments
  ADD COLUMN IF NOT EXISTS fee DECIMAL(10, 2) DEFAULT 0.00;

-- Add student_name column (denormalized for easier querying)
ALTER TABLE appointments
  ADD COLUMN IF NOT EXISTS student_name TEXT;

-- Add payment_status column for tracking payment
ALTER TABLE appointments
  ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'unpaid';

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_appointments_fee ON appointments(fee);
CREATE INDEX IF NOT EXISTS idx_appointments_student_name ON appointments(student_name);
CREATE INDEX IF NOT EXISTS idx_appointments_payment_status ON appointments(payment_status);

-- Refresh schema cache to recognize new columns
NOTIFY pgrst, 'reload schema';
