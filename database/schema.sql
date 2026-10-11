-- ============================================
-- AI LEAD QUALIFICATION SYSTEM
-- Supabase Postgres Schema
-- Version: 1.0.0
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================
-- ENUM TYPES
-- ============================================

CREATE TYPE lead_source AS ENUM (
    'website_form',
    'google_ads',
    'facebook_ads',
    'csv_upload',
    'api_ingestion',
    'phone_sms',
    'manual_entry'
);

CREATE TYPE lead_status AS ENUM (
    'new',
    'processing',
    'qualified',
    'unqualified',
    'needs_followup',
    'contacted',
    'converted',
    'lost',
    'duplicate',
    'invalid'
);

CREATE TYPE event_type AS ENUM (
    'lead_created',
    'lead_updated',
    'lead_deduplicated',
    'qualification_started',
    'qualification_completed',
    'followup_generated',
    'notification_sent',
    'export_completed',
    'status_changed',
    'error_occurred'
);

CREATE TYPE log_level AS ENUM (
    'debug',
    'info',
    'warning',
    'error',
    'critical'
);

-- ============================================
-- CLIENTS TABLE (Multi-tenancy)
-- ============================================

CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    industry VARCHAR(100),
    timezone VARCHAR(50) DEFAULT 'America/New_York',
    qualification_criteria JSONB DEFAULT '{}',
    followup_settings JSONB DEFAULT '{}',
    slack_webhook_url TEXT,
    google_sheet_id VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_clients_slug ON clients(slug);
CREATE INDEX idx_clients_active ON clients(is_active) WHERE is_active = true;

-- ============================================
-- LEADS TABLE (Core)
-- ============================================

CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,

    -- Source tracking
    source lead_source NOT NULL,
    source_id VARCHAR(255),
    source_campaign VARCHAR(255),
    source_medium VARCHAR(100),
    source_raw_data JSONB,

    -- Contact information (normalized)
    email VARCHAR(255),
    email_normalized VARCHAR(255),
    phone VARCHAR(50),
    phone_normalized VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(255),
    company VARCHAR(255),

    -- Location
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'US',

    -- Lead details
    service_requested VARCHAR(255),
    message TEXT,
    budget_range VARCHAR(100),
    urgency VARCHAR(50),
    preferred_contact_method VARCHAR(50),
    preferred_contact_time VARCHAR(100),

    -- Qualification
    status lead_status DEFAULT 'new',
    qualification_score INTEGER CHECK (qualification_score >= 0 AND qualification_score <= 100),
    qualification_reasoning TEXT,
    qualification_model VARCHAR(100),
    qualification_timestamp TIMESTAMPTZ,

    -- Follow-up
    followup_message TEXT,
    followup_generated_at TIMESTAMPTZ,
    followup_sent_at TIMESTAMPTZ,
    followup_channel VARCHAR(50),

    -- Deduplication
    is_duplicate BOOLEAN DEFAULT false,
    duplicate_of_id UUID REFERENCES leads(id),
    fingerprint VARCHAR(64),

    -- Metadata
    ip_address INET,
    user_agent TEXT,
    page_url TEXT,
    referrer_url TEXT,
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    utm_term VARCHAR(255),
    utm_content VARCHAR(255),

    -- Custom fields (flexible)
    custom_fields JSONB DEFAULT '{}',

    -- Timestamps
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,

    -- Constraints
    CONSTRAINT leads_has_contact CHECK (
        email IS NOT NULL OR phone IS NOT NULL
    )
);

-- Indexes for leads
CREATE INDEX idx_leads_client ON leads(client_id);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_source ON leads(source);
CREATE INDEX idx_leads_email_normalized ON leads(email_normalized);
CREATE INDEX idx_leads_phone_normalized ON leads(phone_normalized);
CREATE INDEX idx_leads_fingerprint ON leads(fingerprint);
CREATE INDEX idx_leads_created ON leads(created_at DESC);
CREATE INDEX idx_leads_submitted ON leads(submitted_at DESC);
CREATE INDEX idx_leads_qualification_score ON leads(qualification_score DESC) WHERE qualification_score IS NOT NULL;
CREATE INDEX idx_leads_client_status ON leads(client_id, status);
CREATE INDEX idx_leads_client_source ON leads(client_id, source);
CREATE INDEX idx_leads_not_duplicate ON leads(client_id, is_duplicate) WHERE is_duplicate = false;

-- Trigram index for fuzzy matching
CREATE INDEX idx_leads_email_trgm ON leads USING gin (email_normalized gin_trgm_ops);
CREATE INDEX idx_leads_name_trgm ON leads USING gin (full_name gin_trgm_ops);

-- ============================================
-- EVENTS TABLE (Activity log)
-- ============================================

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,

    event_type event_type NOT NULL,
    event_data JSONB DEFAULT '{}',

    workflow_id VARCHAR(100),
    workflow_execution_id VARCHAR(255),
    node_name VARCHAR(100),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_client ON events(client_id);
CREATE INDEX idx_events_lead ON events(lead_id);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_created ON events(created_at DESC);
CREATE INDEX idx_events_workflow ON events(workflow_id);

-- ============================================
-- MESSAGES TABLE (Generated follow-ups)
-- ============================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,

    message_type VARCHAR(50) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    subject VARCHAR(500),
    body TEXT NOT NULL,

    template_used VARCHAR(100),
    personalization_data JSONB DEFAULT '{}',

    ai_model VARCHAR(100),
    ai_prompt_version VARCHAR(50),
    generation_tokens INTEGER,

    status VARCHAR(50) DEFAULT 'generated',
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,

    external_message_id VARCHAR(255),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_client ON messages(client_id);
CREATE INDEX idx_messages_lead ON messages(lead_id);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

-- ============================================
-- AUDIT LOGS TABLE
-- ============================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,

    table_name VARCHAR(100) NOT NULL,
    record_id UUID,
    action VARCHAR(50) NOT NULL,

    old_data JSONB,
    new_data JSONB,
    changed_fields TEXT[],

    actor_type VARCHAR(50) DEFAULT 'system',
    actor_id VARCHAR(255),

    ip_address INET,
    user_agent TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_client ON audit_logs(client_id);
CREATE INDEX idx_audit_table ON audit_logs(table_name);
CREATE INDEX idx_audit_record ON audit_logs(record_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_action ON audit_logs(action);

-- ============================================
-- ERROR LOGS TABLE
-- ============================================

CREATE TABLE error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,

    level log_level DEFAULT 'error',

    error_code VARCHAR(100),
    error_message TEXT NOT NULL,
    error_stack TEXT,

    workflow_id VARCHAR(100),
    workflow_execution_id VARCHAR(255),
    node_name VARCHAR(100),

    request_data JSONB,
    response_data JSONB,

    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMPTZ,
    resolved_by VARCHAR(255),
    resolution_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_errors_client ON error_logs(client_id);
CREATE INDEX idx_errors_lead ON error_logs(lead_id);
CREATE INDEX idx_errors_level ON error_logs(level);
CREATE INDEX idx_errors_code ON error_logs(error_code);
CREATE INDEX idx_errors_created ON error_logs(created_at DESC);
CREATE INDEX idx_errors_unresolved ON error_logs(is_resolved) WHERE is_resolved = false;
CREATE INDEX idx_errors_workflow ON error_logs(workflow_id);

-- ============================================
-- API KEYS TABLE (Webhook authentication)
-- ============================================

CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,

    key_hash VARCHAR(64) NOT NULL UNIQUE,
    key_prefix VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,

    scopes TEXT[] DEFAULT ARRAY['leads:write'],
    rate_limit INTEGER DEFAULT 100,

    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_client ON api_keys(client_id);
CREATE INDEX idx_api_keys_active ON api_keys(is_active) WHERE is_active = true;

-- ============================================
-- REPORTING VIEWS
-- ============================================

-- Lead summary by source
CREATE VIEW v_leads_by_source AS
SELECT
    client_id,
    source,
    status,
    DATE(created_at) as lead_date,
    COUNT(*) as lead_count,
    AVG(qualification_score) as avg_score,
    COUNT(*) FILTER (WHERE status = 'qualified') as qualified_count,
    COUNT(*) FILTER (WHERE status = 'unqualified') as unqualified_count,
    COUNT(*) FILTER (WHERE status = 'needs_followup') as needs_followup_count
FROM leads
WHERE is_duplicate = false
GROUP BY client_id, source, status, DATE(created_at);

-- Lead funnel metrics
CREATE VIEW v_lead_funnel AS
SELECT
    client_id,
    DATE(created_at) as lead_date,
    COUNT(*) as total_leads,
    COUNT(*) FILTER (WHERE is_duplicate = false) as unique_leads,
    COUNT(*) FILTER (WHERE status IN ('qualified', 'contacted', 'converted')) as qualified_leads,
    COUNT(*) FILTER (WHERE status = 'contacted') as contacted_leads,
    COUNT(*) FILTER (WHERE status = 'converted') as converted_leads,
    AVG(EXTRACT(EPOCH FROM (processed_at - created_at))/60) as avg_processing_minutes
FROM leads
GROUP BY client_id, DATE(created_at);

-- Daily qualification stats
CREATE VIEW v_daily_qualification_stats AS
SELECT
    client_id,
    DATE(qualification_timestamp) as qualification_date,
    COUNT(*) as total_qualified,
    AVG(qualification_score) as avg_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY qualification_score) as median_score,
    MIN(qualification_score) as min_score,
    MAX(qualification_score) as max_score
FROM leads
WHERE qualification_timestamp IS NOT NULL AND is_duplicate = false
GROUP BY client_id, DATE(qualification_timestamp);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Normalize email
CREATE OR REPLACE FUNCTION normalize_email(email TEXT)
RETURNS TEXT AS $$
BEGIN
    IF email IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN LOWER(TRIM(email));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Normalize phone (US format)
CREATE OR REPLACE FUNCTION normalize_phone(phone TEXT)
RETURNS TEXT AS $$
DECLARE
    digits TEXT;
BEGIN
    IF phone IS NULL THEN
        RETURN NULL;
    END IF;
    digits := REGEXP_REPLACE(phone, '[^0-9]', '', 'g');
    IF LENGTH(digits) = 10 THEN
        RETURN '+1' || digits;
    ELSIF LENGTH(digits) = 11 AND LEFT(digits, 1) = '1' THEN
        RETURN '+' || digits;
    ELSE
        RETURN digits;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Generate lead fingerprint for deduplication
CREATE OR REPLACE FUNCTION generate_lead_fingerprint(
    p_email_normalized TEXT,
    p_phone_normalized TEXT,
    p_full_name TEXT
)
RETURNS TEXT AS $$
DECLARE
    fingerprint_input TEXT;
BEGIN
    fingerprint_input := COALESCE(p_email_normalized, '') || '|' ||
                         COALESCE(p_phone_normalized, '') || '|' ||
                         COALESCE(LOWER(TRIM(p_full_name)), '');
    RETURN encode(sha256(fingerprint_input::bytea), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Update timestamps
CREATE TRIGGER tr_clients_updated
    BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_leads_updated
    BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_messages_updated
    BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-normalize and fingerprint leads
CREATE OR REPLACE FUNCTION process_lead_before_insert()
RETURNS TRIGGER AS $$
BEGIN
    NEW.email_normalized := normalize_email(NEW.email);
    NEW.phone_normalized := normalize_phone(NEW.phone);
    NEW.fingerprint := generate_lead_fingerprint(
        NEW.email_normalized,
        NEW.phone_normalized,
        NEW.full_name
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_leads_before_insert
    BEFORE INSERT ON leads
    FOR EACH ROW EXECUTE FUNCTION process_lead_before_insert();

CREATE TRIGGER tr_leads_before_update
    BEFORE UPDATE OF email, phone, full_name ON leads
    FOR EACH ROW EXECUTE FUNCTION process_lead_before_insert();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Service role bypass (for n8n)
CREATE POLICY "Service role full access on clients" ON clients
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on leads" ON leads
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on events" ON events
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on messages" ON messages
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on audit_logs" ON audit_logs
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on error_logs" ON error_logs
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on api_keys" ON api_keys
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- SEED DATA (Default client for testing)
-- ============================================

INSERT INTO clients (id, name, slug, industry, qualification_criteria, followup_settings)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Demo Client',
    'demo',
    'Home Services',
    '{
        "min_score_qualified": 60,
        "min_score_followup": 30,
        "required_fields": ["email", "service_requested"],
        "high_value_services": ["hvac_installation", "roof_replacement", "remodel"],
        "urgency_boost": {"immediate": 20, "this_week": 10, "this_month": 5}
    }',
    '{
        "channels": ["email", "sms"],
        "delay_minutes": 5,
        "max_followups": 3,
        "followup_intervals_hours": [24, 72, 168]
    }'
);
