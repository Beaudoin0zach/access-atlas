-- =============================================================================
-- provision-cloud.sql — one-shot schema for a fresh Supabase CLOUD project.
-- Generated 2026-07-10 from migrations 0001-0007 + the attribute
-- catalog (seed.sql lines 14-32). Contains NO demo listings/confirmations —
-- production data is the reviewed WNY seed, imported separately via
-- scripts/seed-import.mjs. Paste into the Supabase SQL Editor and Run.
-- Regenerate: see the block that produced it in the deploy runbook.
-- =============================================================================

-- ---- supabase/migrations/0001_init.sql ----
-- =============================================================================
-- 0001_init.sql — core schema
--
-- This schema encodes the project constitution (CLAUDE.md). Read §4 (validation
-- model) and §6 (privacy) before changing anything here. The rules below are
-- SAFETY-CRITICAL: a wrongly-"verified" access claim can strand or endanger a
-- person. Bias every ambiguous choice toward caution.
--
-- Design principles baked in:
--   * Attribute-level validation, never an overall star average (§4, §14).
--   * The ONLY allowed labeling vocabulary is the attribute_state enum below.
--   * Data minimization: we never store a person's disability *type* (§6).
--     Reviewer identity tags are COARSE, OPTIONAL, and access-oriented only.
--   * Lived experience is weighted (§2, §4) via relevant_identity_tag.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

-- A listing is a provider OR a place. Schema is shared so the validation
-- machinery (the moat) is uniform across both. (§13 open decision: one vs. two
-- submission flows — the *data* is unified regardless of the UI choice.)
create type listing_kind as enum ('provider', 'place');

-- What sort of claim an attribute is. Drives who can meaningfully confirm it.
create type attribute_category as enum (
  'facility_objective',    -- binary, photo-verifiable (§8b): "entrance has zero steps"
  'provider_behavior',     -- first-person visit report (§8c): "communicated directly with me"
  'provider_self_attested' -- owner affirmation (§8a, ADHCE-mapped): not community-verifiable
);

-- The ONLY allowed labeling vocabulary (§4). Do not add "verified" or
-- "high confidence" strings anywhere else in the codebase; derive from here.
--   self_reported          -> UI: "self-reported / awaiting verification"
--   community_confirmations -> UI: "N community confirmations"
--   community_verified     -> UI: "community-verified" (>= 3 independent confirmations)
--   sourced                -> UI: "sourced" — the ONLY state that may say "high confidence"
--   disputed               -> UI: "disputed — under re-review" (a credible dissent froze it)
create type attribute_state as enum (
  'self_reported',
  'community_confirmations',
  'community_verified',
  'sourced',
  'disputed'
);

-- ---------------------------------------------------------------------------
-- Contributors (pseudonymous — §6)
--
-- We store the minimum. No email is required here; auth (if any) lives in
-- Supabase's auth schema and is intentionally decoupled. `pseudonym` is a
-- display handle, not a real name. We do NOT store disability type, ever.
-- ---------------------------------------------------------------------------
create table contributors (
  id          uuid primary key default gen_random_uuid(),
  pseudonym   text,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Listings (providers + places)
-- ---------------------------------------------------------------------------
create table listings (
  id            uuid primary key default gen_random_uuid(),
  kind          listing_kind not null,
  name          text not null,
  summary       text,
  -- Address kept coarse; precise geocoding is optional because the map is a
  -- progressive enhancement over an equivalent list view (§5). lat/lng nullable.
  street        text,
  city          text,
  region        text,        -- e.g., 'Erie County' — drives the WNY-first rollout (§3)
  postal_code   text,
  lat           double precision,
  lng           double precision,
  submitted_by  uuid references contributors (id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index listings_kind_idx on listings (kind);
create index listings_region_idx on listings (region);

-- Provider-only profile. All three flags are SELF-ATTESTED only — never require
-- medical proof (§6, §12). A provider may be literate, owned, led, any combo, or
-- none; these are independent axes (§1). Definitions (resolved 2026-07-07, §13):
--   disabled_owned = a disabled person holds >= 51% ownership.
--   disabled_led   = a disabled person holds primary leadership / decision-making
--                    (a control test, NOT an ownership percentage).
create table provider_profiles (
  listing_id          uuid primary key references listings (id) on delete cascade,
  disability_literate boolean not null default false, -- serves disabled people well (ADHCE, §8)
  disabled_owned      boolean not null default false, -- self-attested >= 51% disabled ownership (§12)
  disabled_led        boolean not null default false, -- self-attested disabled primary leadership (§12)
  -- ADHCE-mapped affirmation checkboxes captured at sign-up (§8a). Free-form
  -- jsonb so the affirmation set can evolve without a migration.
  self_attestations   jsonb not null default '{}'::jsonb
);

-- ---------------------------------------------------------------------------
-- Attribute catalog — the specific, separately-validated claims (§4, §8)
--
-- Never collapse these into one score. Each row is one thing a person can
-- confirm from their own visit.
-- ---------------------------------------------------------------------------
create table attribute_definitions (
  id                   uuid primary key default gen_random_uuid(),
  key                  text not null unique,         -- 'entrance_step_free'
  label                text not null,                -- 'Step-free entrance'
  category             attribute_category not null,
  applies_to_kind      listing_kind,                 -- null = applies to both
  -- The structured question a confirmer answers FROM THEIR OWN VISIT. This is
  -- how we avoid one-click "me too" agreement (§4, anti trigger-happy).
  question_text        text not null,
  requires_photo       boolean not null default true, -- evidence base (§4, §8b)
  -- Time-decay (§4): physical facts expire. Prompt re-confirmation after this
  -- many days. Resolved 2026-07-07 (§13): uniform 12 months (365) for every
  -- attribute. The column stays per-attribute so a future tiered policy is a
  -- data change, not a migration.
  reverify_interval_days integer not null default 365,
  -- Whose lived experience is weighted for THIS attribute (§4). e.g. a
  -- 'wheelchair_user' tag is weighted for step-free access. Coarse + optional.
  -- null = no specific identity is privileged for this attribute.
  relevant_identity_tag text
);

-- One claim per (listing, attribute): the assertion that this attribute holds.
-- Confirmations accrue against it. `sourced` flips the claim to the sourced
-- state (backed by certification/audit/partner — §4).
create table attribute_claims (
  id               uuid primary key default gen_random_uuid(),
  listing_id       uuid not null references listings (id) on delete cascade,
  attribute_def_id uuid not null references attribute_definitions (id) on delete restrict,
  asserted_value   boolean not null default true,   -- what is being claimed (usually "yes, present")
  sourced          boolean not null default false,  -- backed by audit/cert/partner (§4)
  sourced_note     text,                             -- what the source is (audit name, partner org)
  created_at       timestamptz not null default now(),
  unique (listing_id, attribute_def_id)
);

create index attribute_claims_listing_idx on attribute_claims (listing_id);

-- First-person confirmations. A confirmation is a person answering the
-- attribute's structured question from THEIR OWN visit — not a "me too" (§4).
--   agrees = true  -> their visit confirms the claim's asserted_value
--   agrees = false -> a dissent ("this is NOT accessible") — freezes the claim (§4)
-- `reviewer_identity_tags` are coarse, optional, access-oriented, and never
-- publicly tied to the person (§6). Used only for weighting (§4).
create table confirmations (
  id                    uuid primary key default gen_random_uuid(),
  claim_id              uuid not null references attribute_claims (id) on delete cascade,
  contributor_id        uuid not null references contributors (id) on delete cascade,
  agrees                boolean not null,
  observed_note         text,              -- optional free-text from the visit
  photo_url             text,              -- evidence (§4) — required for objective attributes at the app layer
  reviewer_identity_tags text[] not null default '{}',
  visited_on            date,
  created_at            timestamptz not null default now(),
  -- Independence (§4): one confirmation per person per claim. Prevents a single
  -- contributor padding the consensus count.
  unique (claim_id, contributor_id)
);

create index confirmations_claim_idx on confirmations (claim_id);

-- ---------------------------------------------------------------------------
-- Derived status view — the single source of truth for labeling.
--
-- THE WORKING VALIDATION FORMULA (§4; exact numbers are open decisions, §13):
--   * Any first-person dissent           -> 'disputed' (freeze, pending re-review).
--     Dissent takes precedence over everything, including 'sourced'. The cost of
--     a false positive is borne by a user's body — bias toward caution (§4).
--   * sourced flag                        -> 'sourced'.
--   * >= 3 independent agreeing confirmations, AND (if the attribute privileges
--     a lived-experience tag) >= 1 of them carries that tag -> 'community_verified'.
--   * >= 1 agreeing confirmation          -> 'community_confirmations'.
--   * otherwise                           -> 'self_reported'.
--
-- Staleness (time-decay, §4) is reported alongside state so the UI can surface
-- "last confirmed" and prompt re-confirmation. A stale claim is NOT auto-verified.
-- ---------------------------------------------------------------------------
create view attribute_claim_status as
select
  c.id                                                            as claim_id,
  c.listing_id,
  c.attribute_def_id,
  d.key                                                           as attribute_key,
  d.label,
  d.category,
  d.relevant_identity_tag,
  d.reverify_interval_days,
  c.sourced,
  c.sourced_note,
  count(f.*) filter (where f.agrees)                              as agree_count,
  count(f.*) filter (where not f.agrees)                          as dissent_count,
  count(f.*) filter (
    where f.agrees
      and d.relevant_identity_tag is not null
      and d.relevant_identity_tag = any (f.reviewer_identity_tags)
  )                                                               as weighted_agree_count,
  max(f.created_at) filter (where f.agrees)                       as last_confirmed_at,
  case
    when max(f.created_at) filter (where f.agrees) is null then null
    else max(f.created_at) filter (where f.agrees)
         < now() - make_interval(days => d.reverify_interval_days)
  end                                                             as is_stale,
  case
    -- Dissent freezes first — safety over everything (§4).
    when count(f.*) filter (where not f.agrees) > 0 then 'disputed'::attribute_state
    when c.sourced then 'sourced'::attribute_state
    when count(f.*) filter (where f.agrees) >= 3
         and (
           d.relevant_identity_tag is null
           or count(f.*) filter (
                where f.agrees
                  and d.relevant_identity_tag = any (f.reviewer_identity_tags)
              ) >= 1
         )
      then 'community_verified'::attribute_state
    when count(f.*) filter (where f.agrees) >= 1 then 'community_confirmations'::attribute_state
    else 'self_reported'::attribute_state
  end                                                             as state
from attribute_claims c
join attribute_definitions d on d.id = c.attribute_def_id
left join confirmations f on f.claim_id = c.id
group by c.id, d.id;

-- ---------------------------------------------------------------------------
-- Row Level Security (§6)
--
-- Browsing is public and account-free, so listings/claims/status are readable
-- by anyone. WRITE policies are intentionally NOT granted here — contribution
-- auth is a deliberate, pseudonymous design still being specified (§6, §13).
-- Writes go through trusted server code (service role) until that lands, rather
-- than opening anon writes now. Do not add permissive write policies casually.
-- ---------------------------------------------------------------------------
alter table listings              enable row level security;
alter table provider_profiles     enable row level security;
alter table attribute_definitions enable row level security;
alter table attribute_claims      enable row level security;
alter table confirmations         enable row level security;
alter table contributors          enable row level security;

create policy "public read: listings"
  on listings for select using (true);
create policy "public read: provider_profiles"
  on provider_profiles for select using (true);
create policy "public read: attribute_definitions"
  on attribute_definitions for select using (true);
create policy "public read: attribute_claims"
  on attribute_claims for select using (true);

-- NOTE: confirmations and contributors are deliberately NOT publicly readable
-- as full rows — a person's set of identity tags + visit dates could re-identify
-- them (§6). Aggregate counts are exposed via attribute_claim_status instead.
-- Grant read on the view's underlying aggregation, not the raw rows.
create policy "public read: confirmation aggregates via view only"
  on confirmations for select using (false);
create policy "no public read: contributors"
  on contributors for select using (false);

-- Table-level SELECT for the public roles. RLS (above) decides WHICH rows are
-- visible, but Postgres checks table-level privilege FIRST — without these grants
-- every read fails with "permission denied for table". confirmations and
-- contributors are intentionally omitted (their rows stay private; only the
-- aggregate view is exposed).
grant select on listings, provider_profiles, attribute_definitions, attribute_claims
  to anon, authenticated;

-- The service role is the trusted writer (the contributions/listings endpoints)
-- until Keycloak-scoped auth lands. Grant it explicit DML on every app table
-- rather than relying on platform default-privilege behavior, which is not
-- guaranteed. (SELECT is needed too: INSERT ... RETURNING requires it.)
grant select, insert, update, delete on
  listings, provider_profiles, attribute_definitions, attribute_claims,
  confirmations, contributors
  to service_role;

-- The status view is deliberately left as a SECURITY DEFINER view (we do NOT
-- set security_invoker) so it can aggregate confirmations into counts while the
-- raw confirmation rows remain unreadable (the RLS policies above deny row-level
-- select). This is the privacy boundary: expose "3 confirmations", never the 3
-- people. Grant read on the aggregate view only.
grant select on attribute_claim_status to anon, authenticated;

-- ---- supabase/migrations/0002_evidence_storage.sql ----
-- =============================================================================
-- 0002_evidence_storage.sql — storage bucket for attribute evidence photos (§4).
--
-- Objective attribute claims carry photo evidence (§4: "Photos are the evidence
-- base"). Photos are uploaded ONLY by trusted server code (the confirmations
-- endpoint), which re-encodes them through sharp first to STRIP EXIF/GPS
-- metadata before they ever land here (§6 privacy — a raw phone photo leaks
-- location and device). Never upload a user's raw file directly to this bucket.
--
-- Public-read: an entrance/ramp/restroom-doorway photo is evidence meant to be
-- seen; it carries no personal data once EXIF is stripped. Writes are NOT public
-- (no anon insert policy) — the service role bypasses RLS to write.
-- =============================================================================

insert into storage.buckets (id, name, public)
values ('evidence', 'evidence', true)
on conflict (id) do nothing;

-- Public read of evidence objects (bucket is public, but be explicit).
create policy "public read: evidence objects"
  on storage.objects for select
  using (bucket_id = 'evidence');

-- No insert/update/delete policies for anon/authenticated: uploads flow through
-- the service role only, until the Keycloak-backed contributor identity lands
-- and we can scope writes to an authenticated contributor.

-- ---- supabase/migrations/0003_listing_provenance.sql ----
-- =============================================================================
-- 0003_listing_provenance.sql — provenance + idempotency for imported listings.
--
-- Why: the WNY seed data (research/seed-nys/) is SECONDARY-SOURCE, self-reported
-- data (§4, §7). Two needs follow from that:
--
--   1. Honest labeling (§7). A seeded listing must carry WHERE it came from, so
--      the "self-reported / community-sourced" disclaimer is checkable, not a
--      vibe. `source_url` is that pointer.
--   2. Idempotent re-import. The importer (scripts/seed-import.mjs) must be safe
--      to re-run as the dataset is corrected during review, without creating
--      duplicate listings. `source_ref` is a stable natural key the importer
--      upserts on (unique where present).
--
-- Both are NULL for community-submitted listings (the contribute flow) — this
-- only describes rows that came from a curated import. Nothing here touches the
-- validation formula or the attribute_claim_status view (§4/§13): imported
-- listings still start `self_reported` and earn their state the same way.
-- =============================================================================

alter table listings
  add column source_ref text,   -- stable importer key, e.g. 'wnyil:place:elmwood-village-cafe'
  add column source_url text;   -- provenance the honest-labeling disclaimer can cite (§7)

-- Idempotency: at most one listing per source_ref. A plain (non-partial) unique
-- index is correct here — Postgres treats NULLs as DISTINCT by default, so any
-- number of hand-entered listings (source_ref null) coexist freely, while
-- non-null source_refs are unique. It must NOT be partial: the seed importer's
-- upsert uses `ON CONFLICT (source_ref)`, and Postgres only matches that to a
-- non-partial index on that column.
create unique index listings_source_ref_key
  on listings (source_ref);

comment on column listings.source_ref is
  'Stable natural key for curated imports; the seed importer upserts on it. NULL for community-submitted listings.';
comment on column listings.source_url is
  'Where an imported listing was sourced from — backs the self-reported/community-sourced disclaimer (§7). NULL for community submissions.';

-- ---- supabase/migrations/0004_representation_on_listings.sql ----
-- =============================================================================
-- 0004_representation_on_listings.sql — the representation axis belongs to the
-- business, not just to providers (Gap A from research/seed-nys/gaps.md).
--
-- disabled_owned / disabled_led (§1 representation, §12 definitions) describe WHO
-- OWNS / LEADS a business — a property that is independent of whether the listing
-- is a place or a provider. A disabled-owned CAFE is a `place` (e.g. Fly By Cafe,
-- an SDVOB-certified cafe/B&B), and today it has nowhere to record that because
-- the flags live on provider_profiles (provider-only).
--
-- Fix: hoist the two flags onto the shared `listings` entity so both kinds carry
-- them. disability_literate stays on provider_profiles — THAT one is genuinely
-- provider-only (it's about competently serving disabled patients, §8), not an
-- ownership fact. This is additive + orthogonal to the consensus formula: it does
-- NOT touch attribute_claims, confirmations, or the attribute_claim_status view
-- (§4/§13), so the safety-critical lockstep is unaffected.
-- =============================================================================

alter table listings
  add column disabled_owned boolean not null default false, -- self-attested >= 51% disabled ownership (§12)
  add column disabled_led   boolean not null default false; -- self-attested disabled primary leadership (§12)

-- Carry existing provider values up before dropping them, so no attestation is lost.
update listings l
  set disabled_owned = pp.disabled_owned,
      disabled_led   = pp.disabled_led
  from provider_profiles pp
  where pp.listing_id = l.id;

-- Single source of truth: remove the now-duplicated flags from provider_profiles.
alter table provider_profiles
  drop column disabled_owned,
  drop column disabled_led;

comment on column listings.disabled_owned is
  'Self-attested: a disabled person holds >= 51% ownership (§12). Applies to places AND providers.';
comment on column listings.disabled_led is
  'Self-attested: a disabled person holds primary leadership / decision-making (§12). Applies to places AND providers.';

-- ---- supabase/migrations/0005_listing_category.sql ----
-- =============================================================================
-- 0005_listing_category.sql — a coarse category for scannability.
--
-- `category` is a small controlled vocabulary (src/lib/categories.ts) used purely
-- to help people scan the directory with an icon + label (healthcare, library,
-- transit, ...). It is NOT part of the validation model (§4) — a category never
-- touches an attribute claim's state. Free `text` (nullable), like attribute
-- keys, so adding a category later is a data change, not a migration. NULL is
-- fine and renders as no category.
-- =============================================================================

alter table listings add column category text;

comment on column listings.category is
  'Coarse scannability category (see src/lib/categories.ts): healthcare, disability_services, business, library, arts_culture, parks_recreation, transit. NULL = uncategorised. Not part of the validation model.';

-- ---- supabase/migrations/0006_contributor_identity.sql ----
-- =============================================================================
-- 0006_contributor_identity.sql — key contributors by the Keycloak subject and
-- give the app its own revocable data-access session (§15 + BAS invariant #1).
--
-- Two additions, both drop-in for the Keycloak swap (docs/platform-membership.md):
--
-- 1. contributors.sub — the Keycloak PAIRWISE subject id. Pairwise means each app
--    gets a DIFFERENT stable `sub` for the same person, so identities can't be
--    correlated across platform apps (§6). Nullable: provisional/pre-Keycloak
--    contributors have no sub. Unique: one contributor row per subject.
--
-- 2. contributor_sessions — the app's OWN session, minted AFTER validating the
--    OIDC token against Keycloak's JWKS (layered sessions, invariant #1: the
--    identity token is never itself a data credential). The httpOnly cookie holds
--    a random token; we store only its SHA-256 hash here, so a leaked DB read
--    can't be replayed as a session. Revocable (revoked_at) and expiring.
--
-- Additive + orthogonal to the consensus formula — does NOT touch attribute_claims,
-- confirmations, or attribute_claim_status (§4/§13 lockstep unaffected).
-- =============================================================================

alter table contributors
  add column sub text unique;

comment on column contributors.sub is
  'Keycloak PAIRWISE subject id (per-app; never cross-app, §6). Null for provisional/pre-Keycloak contributors (§15, invariant #3).';

-- The app-owned, revocable session. Keyed by a hash of the cookie token so the
-- raw session token is never stored (leaked DB rows can't be replayed).
create table contributor_sessions (
  id             uuid primary key default gen_random_uuid(),
  contributor_id uuid not null references contributors(id) on delete cascade,
  token_hash     text not null unique,   -- sha256(cookie token); raw token never stored
  created_at     timestamptz not null default now(),
  expires_at     timestamptz not null,
  revoked_at     timestamptz             -- non-null => revoked (logout / admin)
);

create index contributor_sessions_contributor_idx
  on contributor_sessions (contributor_id);

-- Sessions are private, exactly like contributors: never publicly readable, and
-- written only by the trusted service role (the BFF auth routes). Mirrors the
-- 0001 pattern — enable RLS, deny public select, grant DML to service_role only.
alter table contributor_sessions enable row level security;

create policy "no public read: contributor_sessions"
  on contributor_sessions for select using (false);

grant select, insert, update, delete on contributor_sessions to service_role;

-- ---- supabase/migrations/0007_evidence_photos.sql ----
-- =============================================================================
-- 0007_evidence_photos.sql — make the evidence base VISIBLE (§4: "Photos are
-- the evidence base") without weakening the confirmations privacy boundary.
--
-- Two additions:
--
-- 1. confirmations.photo_alt + photo_thumb_url
--    * photo_alt — the contributor's own description of what their photo shows.
--      REQUIRED whenever a photo is attached (enforced by the endpoint): an
--      evidence photo a blind or low-vision user can't read is not evidence for
--      them (§5; a11y crossover audit Tier 3 "alt required on upload").
--    * photo_thumb_url — a small (~320px) thumbnail generated at upload time so
--      listing pages can show evidence within the low-bandwidth budget (§5);
--      the full photo is one click away.
--
-- 2. evidence_photos view — the ONLY public read path for photo evidence.
--    confirmations rows stay unreadable (0001: a person's tag set + visit dates
--    could re-identify them, §6). This view exposes EXCLUSIVELY the photo
--    fields — never notes, never identity tags, never contributor ids. The
--    photo objects themselves are already public by URL (0002: the evidence
--    bucket is public-read, EXIF-stripped), so this reveals nothing new — it
--    just lets pages FIND them. `agrees` is included so dissent evidence is
--    labeled honestly ("problem reported"), and observed_on is a DATE (never a
--    timestamp) — coarse on purpose.
--
-- Orthogonal to the consensus formula — does NOT touch attribute_claim_status
-- (§4/§13 lockstep unaffected).
-- =============================================================================

alter table confirmations
  add column photo_alt text,
  add column photo_thumb_url text;

comment on column confirmations.photo_alt is
  'Contributor-written description of their evidence photo. Required with a photo (endpoint-enforced) — alt text is part of the evidence (§5).';
comment on column confirmations.photo_thumb_url is
  'Small thumbnail generated at upload (§5 low-bandwidth); full photo at photo_url.';

-- The public read path for evidence photos. SECURITY DEFINER on purpose (the
-- same deliberate choice as attribute_claim_status in 0001): it must read
-- confirmations rows that RLS hides, and expose only these columns.
create view evidence_photos as
select
  ac.listing_id,
  f.claim_id,
  f.photo_url,
  f.photo_thumb_url,
  f.photo_alt,
  f.agrees,
  -- DATE, never a timestamp — coarse on purpose (§6 data minimization; the
  -- upload instant could correlate a photo back to a person's visit).
  coalesce(f.visited_on, f.created_at::date) as observed_on
from confirmations f
join attribute_claims ac on ac.id = f.claim_id
where f.photo_url is not null;

grant select on evidence_photos to anon, authenticated;

-- ---- attribute catalog (from seed.sql; NO demo data) ----
insert into attribute_definitions (key, label, category, applies_to_kind, question_text, requires_photo, reverify_interval_days, relevant_identity_tag) values
  ('entrance_step_free', 'Step-free entrance', 'facility_objective', null,
   'On your visit, could you enter with zero steps (level or ramped)?', true, 365, 'wheelchair_user'),
  ('accessible_restroom', 'Accessible restroom present', 'facility_objective', null,
   'On your visit, was there a wheelchair-accessible restroom you could use?', true, 365, 'wheelchair_user'),
  -- accessible_parking applies to BOTH kinds (null): §8b lists accessible parking
  -- as an objective PROVIDER facility attribute too, not just for places (Gap B).
  ('accessible_parking', 'Accessible parking', 'facility_objective', null,
   'On your visit, was there designated accessible parking that was usable?', true, 365, 'wheelchair_user'),
  ('height_adjustable_exam_table', 'Height-adjustable exam table', 'facility_objective', 'provider',
   'On your visit, did the provider have a height-adjustable / low-transfer exam table?', true, 365, 'wheelchair_user'),
  -- accessible_scale: core ADA MDE attribute (§8). Zero seed claims exist anywhere
  -- (no public registry) — it is a first-person/recruitment target (Gap C).
  ('accessible_scale', 'Wheelchair-accessible scale', 'facility_objective', 'provider',
   'On your visit, was there a weight scale you could use as a wheelchair user (roll-on / seated)?', true, 365, 'wheelchair_user'),
  ('communicated_directly', 'Communicated directly with me', 'provider_behavior', 'provider',
   'On your visit, did staff speak directly to you (not only to a companion)?', false, 365, null),
  ('staff_knew_equipment', 'Staff knew how to use accessible equipment', 'provider_behavior', 'provider',
   'On your visit, did staff know how to use their accessible equipment?', false, 365, 'wheelchair_user');
