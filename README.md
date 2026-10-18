# Procure Pulse

Procurement analytics dashboard: track purchase orders, aggregate spend across suppliers and categories, and convert multi-currency spend into a unified USD view.

## Business logic

- **Purchase orders** — each order belongs to a supplier, has a reference, order date, currency, and status, and contains many line items (product, category, quantity, unit price).
- **Multi-currency aggregation** — orders can be denominated in any currency. The analytics service converts every line item to USD using live exchange rates (Frankfurter API) before rolling up totals.
- **Spend breakdowns** — results show total spend, order count, and ranked spend tables by supplier and by category.
- **Asynchronous analysis** — kicking off an analysis enqueues a Sidekiq job (`ProcurementAnalyticsWorker`). The run moves through `pending → processing → completed/failed`, and status is streamed to the frontend in real time over Action Cable.
- **Authentication** — JWT auth via Devise + `devise-jwt`. Signup, login, and logout are exposed under `/api/v1`; all data endpoints require a valid JWT sent in the `Authorization` header.

## Architecture

| Layer | Technology |
|-------|------------|
| API | Rails 8 (API mode), Ruby 3.3.4 |
| Database | PostgreSQL 17 |
| Cache / job broker | Redis 7 |
| Background jobs | Sidekiq |
| Real-time updates | Action Cable over WebSocket |
| Frontend | React 19 + TypeScript + Vite |
| Deployment | Kamal (AWS / any Docker host) |
| Local orchestration | docker-compose |

## Repo layout

```
.
├── backend/            # Rails API (app/, config/, db/, spec/, Dockerfile, Dockerfile.dev)
├── frontend/           # React SPA (src/, vite.config.ts, package.json)
└── docker-compose.yml  # local dev stack (db, redis, web, worker, frontend)
```

## Running a local dev environment

### Prerequisites

- Docker and Docker Compose

### Start the stack

```bash
docker compose up
```

This brings up five services:

| Service | URL | Purpose |
|---------|-----|---------|
| db | `localhost:5433` | PostgreSQL |
| redis | `localhost:6380` | Redis |
| web | `http://localhost:3000` | Rails API |
| worker | — | Sidekiq job processor |
| frontend | `http://localhost:5173` | Vite dev server |

### Database setup (first run)

```bash
docker compose exec web bundle exec rails db:create db:migrate db:seed
```

### Run the test suite

```bash
docker compose exec web bundle exec rspec
```

### Stop the stack

```bash
docker compose down
```

## API reference

All endpoints are under `/api/v1` and require authentication unless noted.

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/signup` | Register a new user |
| POST | `/login` | Log in; returns a JWT in the `Authorization` header |
| DELETE | `/logout` | Revoke the current JWT |
| GET | `/me` | Get the current authenticated user |

### Purchase orders

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/purchase_orders` | List all orders (includes supplier + items) |
| GET | `/purchase_orders/:id` | Get a single order |

### Analytics

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/analytics` | Spend totals by supplier and category, in USD |

### Analysis runs (asynchronous)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/analysis_runs` | Enqueue an analysis job; returns `202 Accepted` |
| GET | `/analysis_runs/:id` | Poll run status and results |

The frontend subscribes to `AnalysisRunChannel` over Action Cable (`ws://localhost:3000/cable`) to receive real-time status broadcasts.

## Environment variables

### Backend

| Variable | Example | Purpose |
|----------|---------|---------|
| `DB_HOST` | `db` | Postgres host |
| `DB_PORT` | `5432` | Postgres port |
| `DB_NAME` | `procure_pulse_development` | Database name |
| `DB_USERNAME` | `procure_pulse` | Database user |
| `DB_PASSWORD` | `procure_pulse_dev` | Database password |
| `REDIS_URL` | `redis://redis:6379/0` | Sidekiq / cache connection |
| `ACTION_CABLE_REDIS_URL` | `redis://redis:6379/1` | Action Cable connection |
| `DEVISE_JWT_SECRET_KEY` | `change-me-in-production` | JWT signing secret |
| `RAILS_ENV` | `development` | Rails environment |
| `RAILS_MAX_THREADS` | `5` | Puma thread count |

### Frontend

| Variable | Example |
|----------|---------|
| `VITE_API_URL` | `http://localhost:3000/api/v1` |
| `VITE_CABLE_URL` | `ws://localhost:3000/cable` |

## Deploying to AWS with Kamal

Procure Pulse uses [Kamal](https://kamal-deploy.org/) for deployment. Kamal builds the production Docker image, pushes it to a registry, and deploys it to your server with zero-downtime restarts via Traefik.

### Prerequisites

- An AWS EC2 instance (or any Linux host) with Docker installed
- SSH access to the instance
- A container registry (Amazon ECR or Docker Hub)
- The `kamal` CLI installed locally: `gem install kamal`

### 1. Configure deployment

Edit `backend/config/deploy.yml` and set:

- `server` — your EC2 host (IP or DNS)
- `registry` — your registry (e.g. `123456789012.dkr.ecr.us-east-1.amazonaws.com` or `docker.io/yourname`)
- `registry_provider` — `dockerhub`, `ghcr`, or another supported provider
- `image` — the image name (e.g. `procure-pulse-backend`)
- `proxy` — public port mapping (default `80:80`)

### 2. Add secrets

Create `backend/.kamal/secrets` with at least:

```
DEVISE_JWT_SECRET_KEY=<long-random-secret>
RAILS_MASTER_KEY=<from config/master.key>
DB_PASSWORD=<strong-db-password>
REDIS_URL=redis://redis:6379/0
ACTION_CABLE_REDIS_URL=redis://redis:6379/1
```

Kamal reads these at deploy time and injects them into the running containers.

### 3. Prepare the server

```bash
cd backend
kamal setup
```

This installs Docker and Traefik on the instance if needed.

### 4. Deploy

```bash
kamal deploy
```

Kamal will:

1. Build the production image from `backend/Dockerfile`
2. Push it to your registry
3. Pull it on the instance
4. Run database migrations via the entrypoint
5. Start the web container with healthchecks and zero-downtime cutover

### Rollback

```bash
kamal rollback
```

## Tech notes

- **Exchange rates**: `ExchangeRates::Client` calls `https://api.frankfurter.dev/v2`. Same-currency conversions short-circuit to rate `1` without a network call.
- **Sidekiq retries**: `ProcurementAnalyticsWorker` retries up to 5 times on failure; the analysis run is marked `failed` and the error is broadcast before the exception is re-raised.
- **Frontend state**: JWT is kept in `sessionStorage`; the auth provider validates the session against `/me` on mount.

## License

MIT