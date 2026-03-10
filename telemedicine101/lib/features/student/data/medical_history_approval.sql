-- Add approval fields to medical history table
-- This enables doctors/school staff to approve medical history records
-- Students can only view; PDF download requires approval

-- Add approval columns if they don't exist
ALTER TABLE medical_history 
ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT false;

ALTER TABLE medical_history 
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);

ALTER TABLE medical_history 
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_medical_history_approved 
ON medical_history(is_approved) 
WHERE is_approved = true;

-- Add comments for documentation
COMMENT ON COLUMN medical_history.is_approved IS 'Whether the medical history has been approved by a doctor or school staff';
COMMENT ON COLUMN medical_history.approved_by IS 'User ID of the doctor/school staff who approved the medical history';
COMMENT ON COLUMN medical_history.approved_at IS 'Timestamp when the medical history was approved';
