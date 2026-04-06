# ApiTokenPool

A Phoenix-based API Token Pool management system with automatic token allocation, expiration handling, and background job processing using Oban.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Running Tests](#running-tests)
- [Code Quality Tools](#code-quality-tools)
- [Project Structure](#project-structure)
- [Available Mix Aliases](#available-mix-aliases)
- [Docker Architecture](#docker-architecture)
- [Troubleshooting](#troubleshooting)
- [Background Jobs](#background-jobs)
- [Learn More](#learn-more)

## Features

- Token pool management with allocation and release mechanisms
- Automatic token expiration handling via background workers
- PostgreSQL database with Ecto
- Background job processing with Oban
- RESTful API endpoints
- Comprehensive test coverage

## Quick Start

Get up and running in 3 steps using Docker:

```bash
# 1. Copy environment variables
cp .env-example .env

# 2. Start services
docker compose up -d --build

# 3. Setup database
docker compose run --rm api_token_pool mix ecto.setup
```

Access the application at [`http://localhost:4000`](http://localhost:4000)

Run tests:
```bash
docker compose run --rm api_token_pool mix test
```

## Prerequisites

- **Docker** >= 20.10
- **Docker Compose** >= 2.0

## Getting Started

### 1. Setup Environment Variables

Copy the example environment file:

```bash
cp .env-example .env
```

The default `.env` configuration should work out of the box:

```env
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_HOST=api_token_pool_db
DATABASE_NAME=api_token_pool_dev
```

### 2. Build and Start Services

Build the Docker images and start all services:

```bash
docker compose up --build
```

Or run in detached mode (background):

```bash
docker compose up -d --build
```

This will:
- Build the application container
- Start PostgreSQL database
- Wait for the database to be healthy
- Start the Phoenix server

### 3. Setup Database

In a new terminal, run the database migrations:

```bash
docker compose run --rm api_token_pool mix ecto.setup
```

### 4. Access the Application

The application will be available at [`http://localhost:4000`](http://localhost:4000)

### Useful Docker Compose Commands

**View logs:**
```bash
docker compose logs -f
```

**View logs for specific service:**
```bash
docker compose logs -f api_token_pool
```

**Stop services:**
```bash
docker compose down
```

**Stop services and remove volumes:**
```bash
docker compose down -v
```

**Restart services:**
```bash
docker compose restart
```

**Execute commands in the container:**
```bash
docker compose run --rm api_token_pool mix [command]
```

**Open IEx shell:**
```bash
docker compose run --rm api_token_pool iex -S mix
```

## Running Tests

### Run All Tests

```bash
docker compose run --rm api_token_pool mix test
```

### Run Tests with Coverage

```bash
docker compose run --rm api_token_pool mix test --cover
```

### Run Tests with Detailed Coverage Report (using ExCoveralls)

```bash
docker compose run --rm api_token_pool mix coveralls
```

For HTML coverage report:

```bash
docker compose run --rm api_token_pool mix coveralls.html
```

The HTML report will be generated in `cover/excoveralls.html`

### Run Specific Test File

```bash
docker compose run --rm api_token_pool mix test test/api_token_pool/use_cases/allocate_token_test.exs
```

### Run Specific Test by Line Number

```bash
docker compose run --rm api_token_pool mix test test/api_token_pool/use_cases/allocate_token_test.exs:42
```

## Code Quality Tools

### Run Code Formatter

```bash
docker compose run --rm api_token_pool mix format
```

Check if code is formatted:

```bash
docker compose run --rm api_token_pool mix format --check-formatted
```

### Run Static Code Analysis (Credo)

```bash
docker compose run --rm api_token_pool mix credo
```

Strict mode:

```bash
docker compose run --rm api_token_pool mix credo --strict
```

### Run Security Analysis (Sobelow)

```bash
docker compose run --rm api_token_pool mix sobelow
```

### Run Type Checker (Dialyzer)

```bash
docker compose run --rm api_token_pool mix dialyzer
```

### Run All CI Checks

Run the same checks that run in CI:

```bash
docker compose run --rm api_token_pool mix ci
```

This will:
- Check code formatting
- Run Credo with strict mode
- Run tests with coverage

### Pre-commit Checks

Before committing, run:

```bash
docker compose run --rm api_token_pool mix precommit
```

This will:
- Compile with warnings as errors
- Remove unused dependencies
- Format code
- Run tests

## Project Structure

```
.
├── config/              # Application configuration
├── lib/
│   ├── api_token_pool/           # Business logic
│   │   ├── use_cases/            # Use case implementations
│   │   └── workers/              # Oban background workers
│   └── api_token_pool_web/       # Web layer (controllers, views)
├── priv/
│   └── repo/
│       └── migrations/           # Database migrations
├── test/                         # Test files
└── mix.exs                      # Project configuration
```

## Available Mix Aliases

- `mix setup` - Install dependencies and setup database
- `mix ecto.setup` - Create database, run migrations, and seeds
- `mix ecto.reset` - Drop database and run setup again
- `mix test` - Run tests (creates test DB if needed)
- `mix ci` - Run CI checks (format check, credo, tests with coverage)
- `mix precommit` - Run pre-commit checks

## Docker Architecture

The project uses Docker Compose for development with the following services:

### Services

1. **api_token_pool** - The main application container
   - Built from the `Dockerfile` (dev stage)
   - Runs Phoenix server on port 4000
   - Auto-reloads code changes via volume mounting
   - Waits for database to be healthy before starting

2. **api_token_pool_db** - PostgreSQL database
   - PostgreSQL 17
   - Exposed on port 5432
   - Persistent data storage via volume
   - Health checks to ensure readiness

### Volumes

- `api_token_pool_db` - Database data persistence
- `api_token_pool_deps` - Compiled dependencies (faster rebuilds)
- `api_token_pool_build` - Build artifacts cache

### Network

- `api_token_pool_net` - Internal network for service communication

### Dockerfile Stages

The `Dockerfile` includes multi-stage builds:

1. **base** - System dependencies and Elixir setup
2. **deps** - Production dependencies
3. **dev** - Development environment with proper user permissions
4. **build** - Compile application for production
5. **app** - Minimal runtime image for production deployment

## Troubleshooting

### Docker Issues

**Port already in use:**
```bash
# Check if port 4000 is already in use
lsof -i :4000

# Stop the process or change the port in compose.yml
```

**Database connection issues:**
```bash
# Check if database is healthy
docker compose ps

# View database logs
docker compose logs api_token_pool_db

# Restart database
docker compose restart api_token_pool_db
```

**Rebuild containers after dependency changes:**
```bash
docker compose down
docker compose up --build
```

**Reset database in Docker:**
```bash
docker compose run --rm api_token_pool mix ecto.reset
```

**Clean everything and start fresh:**
```bash
docker compose down -v
docker compose up --build
docker compose run --rm api_token_pool mix ecto.setup
```

### Permission Issues

If you encounter permission issues with Docker volumes:

```bash
# Set your user ID and group ID
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

# Rebuild with correct permissions
docker compose down
docker compose up --build
```

## Background Jobs

The application uses Oban for background job processing. Jobs are configured to run in the following queues:

- `default`: General purpose jobs (10 workers)
- `tokens`: Token-related jobs (10 workers)

## Learn More

### Phoenix Framework
- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

### Oban (Background Jobs)
- Docs: https://hexdocs.pm/oban
- GitHub: https://github.com/sorentwo/oban

## License

MIT license
