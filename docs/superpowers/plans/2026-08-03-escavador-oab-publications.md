# Escavador OAB Publications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the MVP for receiving and listing Escavador official-journal publications linked to one office OAB.

**Architecture:** Store OAB state on `Office`, receive Escavador callbacks through a public authenticated endpoint, normalize callback payloads into `LegalPublication`, link publications to existing legal cases by CNJ number, and expose a server-rendered publications list with read/unread and linked/unlinked filters.

**Tech Stack:** Rails 8.1.2, PostgreSQL, Minitest, server-rendered ERB, Escavador API callbacks.

## Global Constraints

- Use one OAB per office in this release.
- Keep `offices.oab_registration` as OAB number only and add `offices.oab_state`.
- Normalize `oab_registration` to digits only.
- Normalize `oab_state` to uppercase two-letter Brazilian UF.
- Configure Escavador through `ESCAVADOR_API_TOKEN`, `ESCAVADOR_API_V1_BASE_URL`, `ESCAVADOR_API_V2_BASE_URL`, and `ESCAVADOR_CALLBACK_TOKEN`.
- Reject callbacks whose `Authorization` header does not match `Bearer #{ESCAVADOR_CALLBACK_TOKEN}`.
- Deduplicate Escavador publications by unique `source, external_id`.
- Link a publication to `LegalCase` only when exactly one case in the same office matches the normalized CNJ number.
- Do not support multiple OABs per office in this release.
- Do not import all lawyer processes into `LegalCase` automatically.
- Do not implement WhatsApp notification delivery for publications in this release.
- Do not commit changes unless explicitly authorized.

---

## Tasks

### Task 1: Office OAB Settings

Add `offices.oab_state`, model normalization/validation, controller permit, form field, locale label, and tests.

### Task 2: LegalPublication Model

Add the `legal_publications` table, associations, scopes, dedup indexes, CNJ normalization/linking helper methods, and model tests.

### Task 3: Escavador Callback Ingestion

Add `Integrations::Escavador::PublicationNormalizer`, callback controller, route, authentication, idempotent persistence, case linking, and controller/service tests.

### Task 4: Publications UI

Add `PublicationsController#index`, `mark_read`, routes, server-rendered index view, sidebar navigation, filters for unread/read and linked/unlinked, and controller tests.

### Task 5: Verification

Run migrations, focused tests, full Rails tests, Brakeman, RuboCop, inspect diff, and leave all changes uncommitted.
