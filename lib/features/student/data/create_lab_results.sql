-- SQL Script to create the lab_results table in Supabase
-- Go to your Supabase Dashboard -> SQL Editor and run this query.

CREATE TABLE IF NOT EXISTS public.lab_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    doctor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    test_name TEXT NOT NULL,
    result_value NUMERIC NOT NULL,
    unit TEXT,
    reference_low NUMERIC,
    reference_high NUMERIC,
    status TEXT NOT NULL DEFAULT 'normal' CHECK (status IN ('normal', 'abnormal', 'critical')),
    notes TEXT,
    test_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lab_results_student_id ON public.lab_results(student_id);
CREATE INDEX IF NOT EXISTS idx_lab_results_test_date ON public.lab_results(test_date DESC);

-- Realtime Configuration
alter publication supabase_realtime add table public.lab_results;

-- Row Level Security (RLS) Policies
ALTER TABLE public.lab_results ENABLE ROW LEVEL SECURITY;

-- Students can read their own lab results
CREATE POLICY "Students can read own lab results"
ON public.lab_results FOR SELECT
USING (auth.uid() = student_id);

-- Doctors can read all lab results
CREATE POLICY "Doctors can read all lab results"
ON public.lab_results FOR SELECT
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'));

-- Doctors can insert lab results
CREATE POLICY "Doctors can insert lab results"
ON public.lab_results FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'));

-- Doctors can update lab results they entered
CREATE POLICY "Doctors can update lab results"
ON public.lab_results FOR UPDATE
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'));

-- Doctors can delete lab results
CREATE POLICY "Doctors can delete lab results"
ON public.lab_results FOR DELETE
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'));
