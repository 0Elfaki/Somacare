-- SQL Script to create the medical_histories table in Supabase
-- Go to your Supabase Dashboard -> SQL Editor and run this query.

CREATE TABLE IF NOT EXISTS public.medical_histories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    chronic_conditions TEXT,
    past_illnesses TEXT,
    hospitalizations TEXT,
    family_conditions TEXT,
    surgical_history TEXT,
    allergies TEXT,
    immunizations TEXT,
    social_history TEXT,
    review_of_systems TEXT,
    current_medications TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMP WITH TIME ZONE,
    denial_reason TEXT,
    denied_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    denied_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Realtime Configuration
-- This allows clients to listen for changes to their medical history
alter publication supabase_realtime add table public.medical_histories;

-- Row Level Security (RLS) Policies
ALTER TABLE public.medical_histories ENABLE ROW LEVEL SECURITY;

-- Students can read their own medical history
CREATE POLICY "Students can read own medical history" 
ON public.medical_histories FOR SELECT 
USING (auth.uid() = student_id);

-- Doctors can read all medical histories
CREATE POLICY "Doctors can read all medical histories" 
ON public.medical_histories FOR SELECT 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'));

-- Students can create their own medical history (if they don't have one)
CREATE POLICY "Students can insert own medical history" 
ON public.medical_histories FOR INSERT 
WITH CHECK (auth.uid() = student_id);

-- Students can update their own medical history (if not approved yet)
CREATE POLICY "Students can update own medical history" 
ON public.medical_histories FOR UPDATE 
USING (auth.uid() = student_id);

-- Doctors can update any medical history (for approval, denoting, editing)
CREATE POLICY "Doctors can update medical histories" 
ON public.medical_histories FOR UPDATE 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'));

-- Doctors can insert medical histories
CREATE POLICY "Doctors can insert medical histories" 
ON public.medical_histories FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'));

-- Doctors can delete medical histories
CREATE POLICY "Doctors can delete medical histories" 
ON public.medical_histories FOR DELETE 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'doctor'));
