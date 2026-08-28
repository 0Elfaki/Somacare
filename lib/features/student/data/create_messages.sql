-- SQL Script to create the messages table in Supabase
-- Go to your Supabase Dashboard -> SQL Editor and run this query.
--
-- Backs the student <-> doctor text-messaging screen
-- (lib/features/student/presentation/messaging_chat_screen.dart).
-- One row per chat message; a conversation is identified by the
-- (student_id, doctor_id) pair, optionally scoped to an appointment.

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'voice')),
    body TEXT,
    attachment_url TEXT,
    voice_duration_seconds INTEGER,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT messages_sender_is_participant CHECK (sender_id = student_id OR sender_id = doctor_id)
);

CREATE INDEX IF NOT EXISTS idx_messages_thread
    ON public.messages(student_id, doctor_id, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_appointment_id ON public.messages(appointment_id);

-- Realtime Configuration
alter publication supabase_realtime add table public.messages;

-- Row Level Security (RLS) Policies
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Either participant (the student or the doctor in the thread) can read
CREATE POLICY "Participants can read their messages"
ON public.messages FOR SELECT
USING (auth.uid() = student_id OR auth.uid() = doctor_id);

-- Either participant can send a message, but only as themselves
CREATE POLICY "Participants can send messages"
ON public.messages FOR INSERT
WITH CHECK (
    auth.uid() = sender_id
    AND (auth.uid() = student_id OR auth.uid() = doctor_id)
);

-- Either participant can mark messages as read (updates read_at only, enforced app-side)
CREATE POLICY "Participants can update their thread's messages"
ON public.messages FOR UPDATE
USING (auth.uid() = student_id OR auth.uid() = doctor_id);

-- Senders can delete their own messages
CREATE POLICY "Senders can delete their own messages"
ON public.messages FOR DELETE
USING (auth.uid() = sender_id);
