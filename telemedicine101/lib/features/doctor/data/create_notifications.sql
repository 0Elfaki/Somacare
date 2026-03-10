-- Create notifications table for doctor alerts
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'info', -- 'booking', 'emergency', 'data_reset', 'info'
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data JSONB DEFAULT '{}'::jsonb
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_doctor_id ON notifications(doctor_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Allow doctors to read their own notifications
CREATE POLICY "Doctors can read own notifications" ON notifications
  FOR SELECT USING (doctor_id = auth.uid());

-- Allow system to insert notifications
CREATE POLICY "System can insert notifications" ON notifications
  FOR INSERT WITH CHECK (true);
