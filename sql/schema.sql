-- ============================================================
-- FlowPilot schema (Supabase / PostgreSQL)
-- ============================================================
-- Run once in the Supabase SQL Editor. Safe to re-run.
--
-- The first six tables are adapted from the Life Engine recipe in
-- Nate B. Jones's OB1 project (FSL-1.1-MIT, see LICENSE.md and CREDITS.md).
--
-- Optional, installed separately:
--   * CRM tables (professional_contacts, contact_interactions, opportunities)
--     come from OB1's professional-crm extension:
--     https://github.com/NateBJones-Projects/OB1/tree/main/extensions/professional-crm
--   * Long-term memory search comes from an OB1 Open Brain install
--     (search_thoughts / capture_thought over MCP).
-- FlowPilot skips those sections when the tables or tools aren't there.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Habits the user wants to track
CREATE TABLE IF NOT EXISTS flowpilot_habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  frequency TEXT DEFAULT 'daily'
    CHECK (frequency IN ('daily', 'weekdays', 'weekends', 'weekly', 'custom')),
  time_of_day TEXT DEFAULT 'morning'
    CHECK (time_of_day IN ('morning', 'midday', 'evening', 'anytime')),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- One row per habit completion
CREATE TABLE IF NOT EXISTS flowpilot_habit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  habit_id UUID REFERENCES flowpilot_habits(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT
);

-- Mood, energy, health and custom check-ins
CREATE TABLE IF NOT EXISTS flowpilot_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  checkin_type TEXT NOT NULL
    CHECK (checkin_type IN ('mood', 'energy', 'health', 'custom')),
  value TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Every message FlowPilot sends. Prevents duplicates and feeds the weekly self-review.
CREATE TABLE IF NOT EXISTS flowpilot_briefings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  briefing_type TEXT NOT NULL
    CHECK (briefing_type IN ('morning', 'pre_meeting', 'checkin', 'evening',
                             'habit_reminder', 'weekly_review', 'custom', 'agent_ticket')),
  content TEXT NOT NULL,
  delivered_via TEXT DEFAULT 'discord'
    CHECK (delivered_via IN ('discord', 'telegram')),
  user_responded BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS flowpilot_briefings_type_created_idx
  ON flowpilot_briefings (briefing_type, created_at DESC);

-- Self-improvement suggestions and whether they were approved
CREATE TABLE IF NOT EXISTS flowpilot_evolution (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  change_type TEXT NOT NULL CHECK (change_type IN ('added', 'removed', 'modified')),
  description TEXT NOT NULL,
  reason TEXT,
  approved BOOLEAN DEFAULT false,
  applied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Key/value config and runtime state (one FlowPilot per project)
CREATE TABLE IF NOT EXISTS flowpilot_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ---------- Added by FlowPilot ----------

-- Lightweight tasks and reminders ("done with X" closes them)
CREATE TABLE IF NOT EXISTS flowpilot_pending_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS flowpilot_pending_tasks_open_idx
  ON flowpilot_pending_tasks (user_id) WHERE completed_at IS NULL;

-- Birthdays, renewals, deadlines. Surfaced when inside the reminder window.
CREATE TABLE IF NOT EXISTS important_dates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  date_value DATE NOT NULL,
  reminder_days_before INT NOT NULL DEFAULT 7,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Standing instructions and lessons the agent has learned.
-- If you already have an agent_memories table from another setup, skip this one.
CREATE TABLE IF NOT EXISTS agent_memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id TEXT NOT NULL,
  memory_type TEXT NOT NULL,            -- e.g. 'lesson', 'preference', 'instruction'
  summary TEXT NOT NULL,
  content TEXT,
  provenance_status TEXT,               -- e.g. 'user_confirmed', 'inferred'
  can_use_as_instruction BOOLEAN DEFAULT false,
  can_use_as_evidence BOOLEAN DEFAULT true,
  requires_user_confirmation BOOLEAN DEFAULT true,
  review_status TEXT DEFAULT 'pending', -- 'pending', 'confirmed', 'rejected'
  lifecycle_status TEXT DEFAULT 'active',
  confidence NUMERIC(3,2),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS agent_memories_active_idx
  ON agent_memories (workspace_id, lifecycle_status, can_use_as_instruction);

-- These tables are only reached with the service role key from the server.
-- Turn on RLS with no policies so the public anon key can't read them.
ALTER TABLE flowpilot_habits        ENABLE ROW LEVEL SECURITY;
ALTER TABLE flowpilot_habit_log     ENABLE ROW LEVEL SECURITY;
ALTER TABLE flowpilot_checkins      ENABLE ROW LEVEL SECURITY;
ALTER TABLE flowpilot_briefings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE flowpilot_evolution     ENABLE ROW LEVEL SECURITY;
ALTER TABLE flowpilot_state         ENABLE ROW LEVEL SECURITY;
ALTER TABLE flowpilot_pending_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE important_dates         ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_memories          ENABLE ROW LEVEL SECURITY;

-- Example config (edit, then run)
-- INSERT INTO flowpilot_state (key, value) VALUES
--   ('timezone', 'America/New_York'),
--   ('latitude', '40.71'), ('longitude', '-74.00'),
--   ('news_topics', 'AI, small business'),
--   ('nudge_text', 'Time for a walk!')
-- ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now();
