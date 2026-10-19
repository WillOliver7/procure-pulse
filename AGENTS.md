# Agent context: Procure Pulse

## Purpose

Procurement analytics dashboard. Rails 8 API backend (Ruby 3.3.4) + React 19 / TypeScript frontend (Vite). Users upload/manage purchase orders in any currency; an async worker aggregates spend into USD using live Frankfurter exchange rates, and results stream to the browser over Action Cable.

## Repo layout

```
.
├── backend/                # Rails API (app/, config/, db/, spec/, Dockerfile, Dockerfile.dev)
├── frontend/               # React SPA (src/, vite.config.ts, package.json)
├── docker-compose.yml      # dev stack: db, redis, web, worker, frontend
├── README.md               # user-facing overview, dev setup, Kamal deployment
├── AGENTS.md               # this file
└── ARCHITECTURE.md         # deeper data-flow and design notes
```

## Core business logic

- `PurchaseOrder` belongs to a `Supplier`, has many `PurchaseOrderItem`s; fields: reference (unique), ordered_at, currency, status.
- `ProcurementAnalytics` (backend/app/services/procurement_analytics.rb) loads all orders with supplier + items, converts each item's spend to USD via `ExchangeRates::Client` (Frankfurter API; same-currency short-circuits to rate 1 without a network call), and returns total spend, spend by supplier, and spend by category.
- `AnalysisRun` lifecycle: `pending → processing → completed/failed`. Results are stored as JSONB; errors go in `error_message`. Every status change broadcasts to `AnalysisRunChannel`.
- `ProcurementAnalyticsWorker` (backend/app/workers/procurement_analytics_worker.rb): Sidekiq job, 5 retries. Sets `processing`, runs analytics, sets `completed` with results, or sets `failed` with the error message and re-raises.
- Auth: Devise + `devise-jwt`. JWT sent in `Authorization` header; revocation tracked via `jti` column. Frontend stores token in `sessionStorage` and validates session against `/me` on mount.

## Key files

| File | Role |
|------|------|
| backend/app/services/procurement_analytics.rb | Spend aggregation service |
| backend/app/workers/procurement_analytics_worker.rb | Async analysis job |
| backend/app/channels/analysis_run_channel.rb | Action Cable stream for run status |
| backend/app/services/exchange_rates/client.rb | Frankfurter HTTP client |
| backend/config/routes.rb | API v1 routes + Devise scope endpoints |
| frontend/src/lib/api.ts | Fetch wrapper; JWT from sessionStorage |
| frontend/src/App.tsx | Dashboard: start analysis, subscribe to cable, render AnalysisPanel |
| frontend/src/features/analysis/AnalysisPanel.tsx | Renders run status + results |

## Commands

Start dev stack:
```bash
docker compose up
```

Services: db (localhost:5433), redis (localhost:6380), web (localhost:3000), frontend (localhost:5173), worker (Sidekiq, no port).

DB setup (first run / after migrations):
```bash
docker compose exec web bundle exec rails db:create db:migrate db:seed
```

Run tests:
```bash
docker compose exec web bundle exec rspec
```

Stop:
```bash
docker compose down
```

## Environment variables

Backend: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `REDIS_URL`, `ACTION_CABLE_REDIS_URL`, `DEVISE_JWT_SECRET_KEY`, `RAILS_ENV`, `RAILS_MAX_THREADS`.
Frontend: `VITE_API_URL`, `VITE_CABLE_URL`.

## Gotchas

- `backend/Dockerfile.dev` mounts `./backend:/app`; gems installed at image build time live at `BUNDLE_PATH=/usr/local/bundle` outside the mount.
- `backend/Dockerfile` is multi-stage production (Thruster entrypoint, non-root user, exposes 80).
- `config/cable.yml` uses the Redis adapter in dev and production (not the async adapter).
- `DEVISE_JWT_SECRET_KEY` and `RAILS_MASTER_KEY` are required for production deploys via Kamal (`backend/config/deploy.yml`, `.kamal/secrets`).
- Frontend cable URL defaults to `ws://localhost:3000/cable`; API URL defaults to `http://localhost:3000/api/v1`.

## Test conventions

- RSpec; `rails_helper` + `spec_helper`.
- Specs mirror `app/` structure: `spec/requests/api/`, `spec/services/`, `spec/workers/`, `spec/channels/`, `spec/models/`.
- Worker specs mock `ProcurementAnalytics` and `AnalysisRun.find`; they assert status transitions, `broadcast_status` calls, and error handling.
