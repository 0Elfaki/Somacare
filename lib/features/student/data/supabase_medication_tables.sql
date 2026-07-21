-- Medications table (student's medications)
CREATE TABLE medications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL,
  prescribed_by TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  status TEXT DEFAULT 'active',
  refills_remaining INT DEFAULT 0,
  refills_total INT DEFAULT 0,
  instructions TEXT,
  notes TEXT,
  is_taken_today BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Medication reminders (scheduled notifications)
CREATE TABLE medication_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  scheduled_time TIME NOT NULL,
  days TEXT[] DEFAULT '{"Everyday"}',
  is_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_reminders ENABLE ROW LEVEL SECURITY;

-- Medications policies
CREATE POLICY "Users can view own medications" ON medications FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Users can insert own medications" ON medications FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Users can update own medications" ON medications FOR UPDATE USING (student_id = auth.uid());
CREATE POLICY "Users can delete own medications" ON medications FOR DELETE USING (student_id = auth.uid());

-- Reminders policies
CREATE POLICY "Users can view own reminders" ON medication_reminders FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Users can insert own reminders" ON medication_reminders FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Users can update own reminders" ON medication_reminders FOR UPDATE USING (student_id = auth.uid());
CREATE POLICY "Users can delete own reminders" ON medication_reminders FOR DELETE USING (student_id = auth.uid());
