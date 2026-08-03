# Escavador OAB Publications Design

## Context

Matriz Juridica needs to monitor publications and later processes linked to the office OAB registration. The first release will use one OAB per office and the Escavador API as the external provider.

The current `offices.oab_registration` stores only the OAB number, for example `18727`. The Escavador lawyer-by-OAB endpoints require both the OAB number and the OAB state, so the office settings must also store the state.

Escavador documentation references:

- API overview and V2 lawyer processes endpoint: `https://api.escavador.com/docs`
- Callback documentation for official journal monitoring events: `https://api.escavador.com/v1/docs/callbacks`

## Goals

- Add `oab_state` to office settings and validate it together with `oab_registration`.
- Configure Escavador API credentials through environment variables.
- Receive Escavador official journal callbacks for new publications.
- Persist received publications as first-class records.
- Deduplicate publications from Escavador by external identifier.
- Try to link each publication to an existing `LegalCase` through the CNJ process number.
- Provide a publications list with linked/unlinked and read/unread status.
- Reuse the WhatsApp notification architecture later for `legal_publication_received`.

## Non-Goals

- Supporting multiple OABs per office in this release.
- Scraping official journals directly.
- Importing all lawyer processes into `LegalCase` automatically.
- Creating process monitoring automatically for every returned process.
- Handling private case documents or certificate-based access.
- Building a full notification preference center.

## Office OAB Settings

The office settings form will expose:

- `oab_registration`: OAB number only, for example `18727`.
- `oab_state`: two-letter Brazilian state code, for example `MA`.

Validation rules:

- If `oab_registration` is present, `oab_state` must be present.
- If `oab_state` is present, `oab_registration` must be present.
- `oab_state` is normalized to uppercase and must be a valid Brazilian state code.
- `oab_registration` is normalized to digits only.

This keeps the existing field but makes it safe to use with Escavador API calls such as `oab_estado=MA&oab_numero=18727`.

## Configuration

Environment variables:

```dotenv
ESCAVADOR_API_TOKEN=
ESCAVADOR_API_V1_BASE_URL=https://api.escavador.com/api/v1
ESCAVADOR_API_V2_BASE_URL=https://api.escavador.com/api/v2
ESCAVADOR_CALLBACK_TOKEN=
```

`ESCAVADOR_CALLBACK_TOKEN` is compared with the callback `Authorization` header. The callback endpoint rejects missing or mismatched tokens.

## Data Model

Create `LegalPublication`:

- `office_id`
- `legal_case_id`, optional
- `source`, default `escavador`
- `external_id`
- `event_name`
- `published_at`
- `court_name`
- `journal_name`
- `process_number`
- `title`
- `content`
- `raw_payload`, JSONB
- `read_at`
- timestamps

Indexes:

- Unique index on `source, external_id`.
- Index on `office_id, read_at`.
- Index on `office_id, legal_case_id`.
- Index on `process_number`.

The unique source/external ID prevents duplicates when Escavador retries callbacks.

## Callback Flow

Add a public callback route, for example:

```text
POST /integrations/escavador/callbacks
```

Flow:

1. Validate `Authorization` header against `ESCAVADOR_CALLBACK_TOKEN`.
2. Accept JSON callback payloads.
3. Route supported events to a normalizer.
4. Persist a `LegalPublication`.
5. Deduplicate by `source/external_id`.
6. Try to link to an existing legal case by normalized CNJ number.
7. Leave unrecognized payload details in `raw_payload`.
8. Return 200 for already-processed duplicate callbacks.

Supported publication events for the MVP:

- `diario_movimentacao_nova`
- `diario_citacao_nova`
- `nova_movimentacao` when the movement type identifies an official journal publication.

Unknown callback events return 202 and are logged, without creating records.

## Publication Normalization

Create `Integrations::Escavador::PublicationNormalizer`.

The normalizer returns structured attributes:

- `external_id`
- `event_name`
- `published_at`
- `court_name`
- `journal_name`
- `process_number`
- `title`
- `content`
- `raw_payload`

Because callback payloads can vary by event and API version, normalization should be defensive:

- Prefer stable IDs from payload entities.
- Fall back to the callback UUID when needed.
- Extract CNJ process numbers from explicit fields first.
- Fall back to regex extraction from content only when explicit fields are missing.

## Linking Rules

Publication-to-case linking starts conservative:

1. Normalize publication `process_number` and `LegalCase.external_number` to digits.
2. Link only when there is exactly one matching legal case in the same office.
3. If no match or multiple matches exist, save as unlinked.

Unlinked publications appear in the publications list for manual review. Manual linking can be implemented in a later iteration if needed.

## UI

Add a `PublicationsController#index` and a menu entry named `Publicacoes`.

The first list can be server-rendered and should support:

- unread/read filter
- linked/unlinked filter
- date ordering by `published_at desc`
- link to the related legal case when present
- action to mark a publication as read

Legal case detail integration is optional in the first implementation. If included, it should show recent linked publications in the timeline/detail view without replacing existing process movements.

## Escavador Process Discovery Extension

After publications are stable, add a job:

```ruby
Escavador::ImportLawyerProcessesJob
```

It will call:

```text
GET /api/v2/advogado/processos?oab_estado=MA&oab_numero=18727
```

The job should not automatically create `LegalCase` records in the first extension. It should store or present candidate process numbers for review, then allow explicit linking/import.

## Notifications Extension

After publication persistence is working, add notification event:

```text
legal_publication_received
```

Recipients:

- active opted-in admins from the publication office for the first version
- later: responsible user or responsible team when the publication is linked to a case

Use the existing WhatsApp/Twilio template-based notification infrastructure.

## Error Handling

- Missing Escavador token in outbound client: raise configuration error for manual jobs.
- Missing callback token in production: reject callbacks with 401.
- Invalid callback JSON: return 400.
- Duplicate callback: return 200 without creating another publication.
- Normalization failure: log and return 422.
- Unknown event: log and return 202.

## Testing

Coverage should include:

- Office OAB state/number normalization and validation.
- Escavador callback authentication.
- Callback duplicate idempotency.
- Normalizer extracting publication fields from representative payloads.
- Legal case linking by CNJ number in the same office.
- No linking when the process belongs to another office.
- Publications list filters for unread/read and linked/unlinked.
- Mark-as-read action.

## Rollout

1. Deploy schema and configuration.
2. Configure `ESCAVADOR_API_TOKEN` and `ESCAVADOR_CALLBACK_TOKEN`.
3. Register the callback URL in the Escavador panel.
4. Configure the office OAB number and state.
5. Enable journal monitoring in Escavador for the office OAB/term.
6. Verify with a simulated callback before relying on production events.
