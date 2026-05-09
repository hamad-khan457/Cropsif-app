-- =============================================================================
-- Migration 002: Module 2 — Land Portfolio & Crop Planning
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- parcels
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS parcels (
  id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id     UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         VARCHAR(100)  NOT NULL,
  location     VARCHAR(200),
  area_acres   DECIMAL(10,3),
  soil_type    VARCHAR(50),
  ph_level     DECIMAL(4,2),
  nitrogen     DECIMAL(8,2),
  phosphorus   DECIMAL(8,2),
  potassium    DECIMAL(8,2),
  irrigation   VARCHAR(50),
  coordinates  JSONB,              -- [{lat, lng}] polygon vertex array
  active_crop  VARCHAR(100),
  ndvi_score   DECIMAL(4,3),       -- latest weekly NDVI (set by satellite module)
  is_active    BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_parcels_owner_id ON parcels(owner_id);

-- ---------------------------------------------------------------------------
-- crop_history  (2–3 seasons per parcel for AI planning context)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS crop_history (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  parcel_id   UUID         NOT NULL REFERENCES parcels(id) ON DELETE CASCADE,
  crop_name   VARCHAR(100) NOT NULL,
  season      VARCHAR(20)  CHECK (season IN ('rabi','kharif','zaid')),
  year        SMALLINT,
  yield_mds   DECIMAL(10,2),
  notes       TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crop_history_parcel_id ON crop_history(parcel_id);

COMMIT;
