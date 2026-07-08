# WNY seed conversion notes

`listings.json` (the research batch, 49 records) → `wny-2026-07.seed.json`
(importer format), via `convert.mjs`. **This is a candidate for review — not yet
reviewed, not yet imported.** Every claim imports as `self_reported` (§4).

Re-run any time: `node research/seed-nys/convert.mjs`
Validate shape (no DB needed): `npm run seed:import -- research/seed-nys/wny-2026-07.seed.json --dry-run`

## Result

- **48** listings written (**1** dropped), **34** attribute claims.
- 25 places + 23 providers → the UB Special Care Dental Clinic was dropped.

## Automated decisions (deterministic, from gaps.md §4)

| Action | Rule | Records |
|---|---|---|
| **Excluded listing** | `planned_2027_not_operational` — not open yet, don't surface | UB Special Care Dental Clinic (Squire Hall) |
| **Dropped attribute claims** (listing kept, no claim until a visit) | physical-safety caution — never assert access that's partial / elevator-dependent / not-yet-built (§4) | Shea's Buffalo Theatre (`partial_accessibility_caution`), NFTA Lafayette Square (`elevator_dependent_underground`), Tifft Nature Preserve (`project_in_progress_reverify`) |
| **Promoted `accessible_parking`** | Gap B is fixed — providers can now hold parking; the research had held these as notes | People Inc. Health Services Bldg, Jericho Road — Doat St Clinic |
| **Mapped** | `candidate_id`→`source_ref` (`wny:<kind>:<id>`), `attribute_key`→`key`, `provider_profile.disability_literate`→`provider.disability_literate`, top-level `disabled_owned`/`disabled_led` kept | all |

Each record keeps a `_review` field (the research `flags` + `source_notes`). The
importer ignores underscore fields; it's there for the reviewer.

## What the human reviewer MUST still do before import

1. **Sign off on every `source_url`.** Import is honest only if each is real (§7).
   Watch the flagged ones: `source_fetch_403_reverify` (Explore & More — re-fetch),
   `press_release_source_corroborate` (Catholic Health ASL), `self_listed_directory_medium_reliability` (Aveteran).
2. **Restore nuanced claims on the 3 safety-caution records** if warranted, with the
   caveat surfaced (Shea's has no elevator; Lafayette Square depends on elevators;
   Tifft's trail rebuild must be confirmed complete).
3. **Confirm the promoted parking claims** read right (they cite the developer /
   211WNY pages, not an audit — `self_reported`, must be visit-confirmed).
4. **Decide the veteran-skew disclosure** for disabled-owned records (`sdvob_veteran_subset`):
   6 of 8 are service-disabled-veteran-owned. Real coverage bias — name it, don't hide it.
5. **Addresses:** several SDVOB records have `street: null` (`missing_street_address` /
   `address_may_be_mailing`) — resolve at onboarding.
6. **Region scope:** `outside_erie_county` / `statewide_anchor_context_only` records are
   context, not Erie-density — keep, but don't count them toward the §3 density target.

## What was intentionally NOT imported (by design, not omission)

- **MDE claims** (`height_adjustable_exam_table`, `accessible_scale`): zero — no public
  registry exists. These come only from first-person visits / the July 8 + Aug 9 2026
  deadline recruitment push (gaps.md §2b).
- **Provider behaviors** (`communicated_directly`, `staff_knew_equipment`): zero by
  design — first-person only (§8c). The moat, working as intended.
- **`automatic_doors`, dental tilt-lift, panoramic X-ray**: no schema key yet (Gaps D +
  dental, deferred). Held in the raw research notes.
