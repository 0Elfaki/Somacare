-- Doctor-Patients relationship table
-- This table tracks the relationship between doctors and their patients

CREATE TABLE doctor_patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID REFERENCES auth.users(id),
  student_id UUID REFERENCES auth.users(id),
  sessions_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(doctor_id, student_id)
);

-- Enable Row Level Security
ALTER TABLE doctor_patients ENABLE ROW LEVEL SECURITY;

-- Doctors can see their own patients
CREATE POLICY "Doctors can view their own patients" ON doctor_patients
  FOR SELECT
  USING (auth.uid() = doctor_id);

-- Students can see their own doctor relationships
CREATE POLICY "Students can view their own doctor relationships" ON doctor_patients
  FOR SELECT
  USING (auth.uid() = student_id);

-- Function to automatically create doctor-patient relationship when appointment is booked
CREATE OR REPLACE FUNCTION create_doctor_patient_relationship()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO doctor_patients (doctor_id, student_id)
  VALUES (NEW.doctor_id, NEW.student_id)
  ON CONFLICT (doctor_id, student_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create relationship when appointment is created
CREATE TRIGGER on_appointment_created
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION create_doctor_patient_relationship();

-- Index for faster queries
CREATE INDEX idx_doctor_patients_doctor_id ON doctor_patients(doctor_id);
CREATE INDEX idx_doctor_patients_student_id ON doctor_patients(student_id);
