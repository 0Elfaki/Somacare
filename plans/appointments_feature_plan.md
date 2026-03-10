# Appointments Feature Implementation Plan

## Overview
Implement consolidated appointments system with:
1. Appointments reflecting on both doctor & student home screens
2. Unified booking + appointment creation flow
3. Emergency instant start option for immediate consultations

---

## Current State Analysis

### Database Schema (appointments table)
- `id` - UUID (primary key)
- `student_id` - UUID (references profiles)
- `doctor_id` - UUID (references profiles) ✅
- `doctor_name` - TEXT
- `date` - TEXT (ISO date string)
- `time` - TEXT
- `status` - TEXT (pending/confirmed/completed/cancelled)
- `reason` - TEXT
- `doctor_notes` - TEXT

### Current Screens
- **Student**: `book_appointment_screen.dart`, `my_appointments_screen.dart`
- **Doctor**: `doctor_appointments_screen.dart`, `doctor_dashboard_screen.dart`

---

## Requirements Breakdown

### 1. Appointments on Both Home Screens

**Student Home Screen:**
- Show upcoming appointments summary widget
- Quick access to "Book Appointment" 
- Show appointment status (pending/confirmed)

**Doctor Home Screen:**
- Show today's appointments
- Show upcoming appointments count
- Quick access to start consultation

**Implementation:**
- Add appointments query to both home screens
- Create reusable appointment card widget
- Real-time updates via Supabase subscriptions

### 2. Consolidated Booking Flow

**Current Flow:**
- Separate "Book Appointment" screen
- Select doctor → Select date/time → Confirm

**New Consolidated Flow:**
- Single screen: `appointment_screen.dart`
- Options: "Schedule Appointment" OR "Start Now (Emergency)"
- If "Start Now": Skip date/time selection, auto-set status to "confirmed"

### 3. Emergency Instant Start

**Features:**
- "Start Now" button on booking screen
- When selected:
  - Auto-set `date` to today's date
  - Auto-set `time` to current time
  - Auto-set `status` to "confirmed"
  - Notify doctor immediately
  - Allow instant video consultation

---

## Implementation Tasks

### Phase 1: Database & Backend
- [ ] Add `is_emergency` BOOLEAN column to appointments (default: false)
- [ ] Add `started_at` TIMESTAMP for emergency starts
- [ ] Create RLS policy for students to see their own appointments

### Phase 2: Student Home Screen
- [ ] Add `AppointmentsSummaryWidget` to student dashboard
- [ ] Show next 3 upcoming appointments
- [ ] Link to full appointments list

### Phase 3: Doctor Home Screen  
- [ ] Add `TodayAppointmentsWidget` to doctor dashboard
- [ ] Show "Start Consultation" button for confirmed appointments
- [ ] Real-time updates

### Phase 4: Consolidated Booking Screen
- [ ] Redesign `book_appointment_screen.dart` 
- [ ] Add "Start Now (Emergency)" toggle
- [ ] Conditional date/time fields (hide for emergency)
- [ ] Auto-create appointment for emergency

### Phase 5: Emergency Flow
- [ ] Add "Start Now" button on doctor appointments
- [ ] Update appointment status to "in_progress"
- [ ] Trigger notification to student
- [ ] Navigate to video consultation

---

## UI/UX Changes

### Student Home Screen
```
┌─────────────────────────────────┐
│  Welcome, [Name]                │
├─────────────────────────────────┤
│  📅 My Appointments             │
│  ┌─────────────────────────┐   │
│  │ Dr. Smith - 2pm Today   │   │
│  │ Status: Confirmed       │   │
│  └─────────────────────────┘   │
│  [+ Book New Appointment]       │
└─────────────────────────────────┘
```

### Consolidated Booking Screen
```
┌─────────────────────────────────┐
│  Book Appointment        [X]   │
├─────────────────────────────────┤
│  ○ Schedule for later           │
│  ⚡ Start Now (Emergency)       │
├─────────────────────────────────┤
│  Select Doctor                  │
│  [Dr. Smith - Available]        │
├─────────────────────────────────┤
│  Date: [Mar 10, 2026]          │  ← Hidden if Emergency
│  Time: [2:00 PM]               │  ← Hidden if Emergency
├─────────────────────────────────┤
│  Reason: [                      ]│
│          ]                      │
├─────────────────────────────────┤
│  [Confirm Booking]              │
└─────────────────────────────────┘
```

---

## Files to Modify
1. `lib/features/doctor/data/supabase_doctor_tables.sql` - Add columns
2. `lib/features/student/presentation/student_dashboard_screen.dart` - Add appointments widget
3. `lib/features/student/presentation/book_appointment_screen.dart` - Redesign for consolidation
4. `lib/features/doctor/presentation/doctor_dashboard_screen.dart` - Add today appointments
5. `lib/features/doctor/presentation/doctor_appointments_screen.dart` - Add start now button

---

## Dependencies
- Supabase realtime subscriptions (for live updates)
- Existing notification system (or create new)

---

## Priority Order
1. Database schema changes
2. Student home screen appointments display
3. Doctor home screen appointments display  
4. Consolidated booking screen
5. Emergency instant start
