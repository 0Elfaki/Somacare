-- ============================================================================
-- INSERT 5 DOCTOR PROFILES (one for each auth user)
-- ============================================================================

-- Run this to create doctor profiles (assuming auth users exist):
INSERT INTO profiles (id, role, full_name, school_id, created_at, specialization, license_number, working_hours) VALUES
((SELECT id FROM auth.users WHERE email = 'dr.sarah.johnson@somacare.app'), 'doctor', 'Dr. Sarah Johnson', '44e8bc23-a4e4-461e-bee8-c5b3991b4db9', NOW(), 'General Practice', 'LIC-GP-001', '09:00 - 17:00'),
((SELECT id FROM auth.users WHERE email = 'dr.michael.chen@somacare.app'), 'doctor', 'Dr. Michael Chen', '44e8bc23-a4e4-461e-bee8-c5b3991b4db9', NOW(), 'Pediatrics', 'LIC-PED-002', '08:00 - 16:00'),
((SELECT id FROM auth.users WHERE email = 'dr.emily.williams@somacare.app'), 'doctor', 'Dr. Emily Williams', '44e8bc23-a4e4-461e-bee8-c5b3991b4db9', NOW(), 'Dermatology', 'LIC-DERM-003', '10:00 - 18:00'),
((SELECT id FROM auth.users WHERE email = 'dr.james.anderson@somacare.app'), 'doctor', 'Dr. James Anderson', '44e8bc23-a4e4-461e-bee8-c5b3991b4db9', NOW(), 'Psychiatry', 'LIC-PSY-004', '09:00 - 17:00'),
((SELECT id FROM auth.users WHERE email = 'dr.lisa.martinez@somacare.app'), 'doctor', 'Dr. Lisa Martinez', '44e8bc23-a4e4-461e-bee8-c5b3991b4db9', NOW(), 'General Practice', 'LIC-GP-005', '08:00 - 15:00');
