# Architecture notes

## Data flow

```
PurchaseOrder (currency: EUR, ...)
  └─ has_many PurchaseOrderItem (quantity, unit_price)
        │
        ▼
ProcurementAnalytics#call
  ├─ ExchangeRates::Client#rate(from: EUR, to: USD)  # Frankfurter API, cached per currency
  ├─ item_spend = quantity * unit_price * rate
  ├─ total_spend_usd += item_spend
  ├─ spend_by_supplier[supplier.name] += item_spend
  └─ spend_by_category[item.category] += item_spend
        │
        ▼
AnalysisRun.results = { currency: "USD", order_count, total_spend_usd,
                        spend_by_supplier: [...], spend_by_category: [...] }
        │
        ▼
AnalysisRunChannel.broadcast_to(run, { id, status, results, error_message })
        │
        ▼
Frontend: Action Cable subscription → AnalysisPanel re-renders
```

## Analysis run lifecycle

1. `POST /api/v1/analysis_runs` → `AnalysisRunsController#create` creates run (`status: pending`), enqueues `ProcurementAnalyticsWorker.perform_async`, returns `202 Accepted` with `job_id`.
2. Sidekiq worker fetches run, updates to `processing`, clears `error_message`, broadcasts status.
3. Worker calls `ProcurementAnalytics.new.call`. On success: updates run to `completed` with `results`, broadcasts. On failure: updates run to `failed` with `error_message`, broadcasts, re-raises (Sidekiq retries up to 5 times).

## Authentication

- `devise-jwt` with JTIMatcher revocation strategy. Every issued JWT has a `jti` stored on the `users` table; logout deletes/matches the jti to revoke.
- Endpoints under `devise_scope :user`: `POST /api/v1/signup`, `POST /api/v1/login`, `DELETE /api/v1/logout`.
- All other `api/v1` endpoints use `before_action :authenticate_user!`.
- Frontend sends the JWT in the `Authorization` header on every request; `logoutRequest` calls the server then clears `sessionStorage`.

## Real-time

- Action Cable mounted at `/cable`; Redis adapter in dev/production (`config/cable.yml`).
- `AnalysisRunChannel#subscribed` streams for a given analysis run ID (`stream_for analysis_run`).
- Frontend (`frontend/src/App.tsx`) creates a consumer at `VITE_CABLE_URL`, subscribes to `{ channel: "AnalysisRunChannel", id }`, and fetches the run's show endpoint for initial state.

## Deployment

- Kamal (`backend/config/deploy.yml`, `.kamal/secrets`). Builds `backend/Dockerfile`, pushes to registry, deploys to the configured server with Traefik proxying port 80.
- Dev uses `docker-compose.yml` with separate `Dockerfile.dev` for hot-reloadable source mounts.

## Trade-offs and sharp edges

- `ExchangeRates::Client` makes a live HTTP call per distinct currency; rates are cached in memory (`@rates` hash) only for the duration of one `call`. Under high order volume this is N+1 HTTP calls; consider pre-fetching or a fallback cache if Frankfurter is slow.
- `ProcurementAnalyticsWorker` re-raises after marking failed, so Sidekiq will retry and re-broadcast. The run stays `failed` on subsequent retries unless the worker is changed to skip re-processing.
- `Dockerfile.dev` overlays `./backend:/app`; do not `bundle install` into the container's default path expecting it to persist across `docker compose down` without a named volume for gems.
