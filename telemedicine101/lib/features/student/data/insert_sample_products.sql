-- ============================================================================
-- Sample Products for Medical Store
-- ============================================================================
-- Run this SQL to add 25 sample products to your medical store
-- ============================================================================

INSERT INTO products (name, description, price, original_price, category, in_stock, rating, review_count, prescription_required, image_url) VALUES
-- Medicines (5 products)
('Amoxicillin 500mg', 'Antibiotic for treating bacterial infections. Take as prescribed by your doctor.', 12.99, 15.99, 'medicines', true, 4.8, 124, true, '💊'),
('Ibuprofen 400mg', 'Pain reliever and anti-inflammatory. For headaches, muscle pain, and fever.', 8.99, NULL, 'medicines', true, 4.6, 89, false, '💊'),
('Cetirizine 10mg', 'Antihistamine for allergy relief. 24-hour relief from allergy symptoms.', 10.49, 12.99, 'medicines', true, 4.7, 156, false, '💊'),
('Metformin 500mg', 'Diabetes medication for managing blood sugar levels.', 18.99, NULL, 'medicines', true, 4.9, 203, true, '💊'),
('Lisinopril 10mg', 'ACE inhibitor for treating high blood pressure.', 14.99, NULL, 'medicines', true, 4.5, 78, true, '💊'),

-- Supplements (5 products)
('Vitamin D3 1000 IU', 'Essential vitamin for bone health and immune support.', 15.99, 19.99, 'supplements', true, 4.9, 312, false, '💊'),
('Vitamin C 500mg', 'Immune system support with zinc. Great for cold and flu season.', 9.99, NULL, 'supplements', true, 4.7, 245, false, '💊'),
('Multivitamin Complex', 'Complete daily multivitamin for overall health and wellness.', 22.99, 28.99, 'supplements', true, 4.8, 189, false, '💊'),
('Omega-3 Fish Oil', 'Heart health supplement with EPA and DHA fatty acids.', 19.99, NULL, 'supplements', true, 4.6, 167, false, '💊'),
('Iron Supplements', 'Iron tablets for preventing and treating iron deficiency anemia.', 11.99, NULL, 'supplements', true, 4.4, 92, false, '💊'),

-- First Aid (5 products)
('First Aid Kit - Complete', 'Comprehensive first aid kit with 100+ items for emergencies.', 34.99, 44.99, 'firstAid', true, 4.9, 456, false, '🩹'),
('Sterile Bandages Pack', 'Assorted sterile bandages in various sizes. 50 pieces.', 8.99, NULL, 'firstAid', true, 4.7, 234, false, '🩹'),
('Antiseptic Solution', 'Povidone-iodine antiseptic solution for wound cleaning.', 6.99, NULL, 'firstAid', true, 4.5, 123, false, '🧴'),
('Instant Cold Pack', 'Single-use cold pack for injuries. Activates on squeeze.', 3.99, NULL, 'firstAid', true, 4.3, 67, false, '🧊'),
('Digital Thermometer', 'Fast and accurate digital body thermometer.', 12.99, 15.99, 'firstAid', true, 4.8, 345, false, '🌡️'),

-- Personal Care (5 products)
('Hand Sanitizer 500ml', 'Alcohol-based hand sanitizer with moisturizing agents.', 7.99, NULL, 'personalCare', true, 4.6, 289, false, '🧴'),
('Face Masks (50 pack)', 'Disposable 3-ply face masks for protection.', 19.99, 24.99, 'personalCare', true, 4.7, 567, false, '😷'),
('Digital Blood Pressure Monitor', 'Automatic digital BP monitor with memory function.', 45.99, 59.99, 'personalCare', true, 4.8, 234, false, '💉'),
('Glucometer Kit', 'Blood glucose monitoring system with test strips.', 29.99, NULL, 'personalCare', true, 4.5, 156, false, '🩸'),
('Pulse Oximeter', 'Fingertip pulse oximeter for SpO2 and pulse rate.', 24.99, 29.99, 'personalCare', true, 4.7, 198, false, '❤️'),

-- Devices (5 products)
('Nebulizer Machine', 'Portable mesh nebulizer for respiratory treatment.', 49.99, 59.99, 'devices', true, 4.8, 89, true, '呼吸'),
('Heat Therapy Pad', 'Electric heating pad with adjustable temperature.', 25.99, NULL, 'devices', true, 4.6, 145, false, '♨️'),
('TENS Pain Relief Device', 'Transcutaneous electrical nerve stimulation for pain relief.', 39.99, 49.99, 'devices', true, 4.5, 78, false, '⚡'),
('Air Purifier HEPA', 'Compact air purifier with HEPA filter for home use.', 79.99, NULL, 'devices', true, 4.7, 234, false, '🌬️'),
('Humidifier', 'Ultrasonic cool mist humidifier for better breathing.', 34.99, 42.99, 'devices', true, 4.6, 167, false, '💨');
