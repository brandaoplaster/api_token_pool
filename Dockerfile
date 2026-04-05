# ============================================
# Stage 0: Common base (system dependencies)
# ============================================
FROM elixir:1.19.1-alpine AS base

RUN apk add --no-cache \
    build-base \
    git \
    openssh-client \
    postgresql-dev \
    && rm -rf /var/cache/apk/*

WORKDIR /app
RUN mix do local.hex --force, local.rebar --force

# ============================================
# Stage 1: Dependencies (better caching)
# ============================================
FROM base AS deps

# Copy only dependency files first
COPY mix.exs mix.lock ./
RUN --mount=type=ssh mix deps.get --only prod

# ============================================
# Stage 2: Development
# ============================================
FROM base AS dev

ARG USER_ID=1000
ARG GROUP_ID=1000

# Create user and group with host IDs
RUN addgroup -g $GROUP_ID appuser || true && \
    adduser -u $USER_ID -G appuser -h /home/appuser -s /bin/sh -D appuser || true

# Remove /app created as root and recreate with correct permissions
RUN rm -rf /app && \
    mkdir -p /app/deps /app/_build /home/appuser/.mix /home/appuser/.hex && \
    chown -R $USER_ID:$GROUP_ID /app /home/appuser && \
    chmod -R 775 /app

# Copy Hex and Rebar from root to appuser
RUN cp -r /root/.mix/* /home/appuser/.mix/ 2>/dev/null || true && \
    cp -r /root/.hex/* /home/appuser/.hex/ 2>/dev/null || true && \
    chown -R $USER_ID:$GROUP_ID /home/appuser/.mix /home/appuser/.hex

WORKDIR /app

# The rest will be set up via volume in Compose

# ============================================
# Stage 3: Build (production)
# ============================================
FROM deps AS build

ARG mix_env=prod
WORKDIR /app

# 2. Configurations
COPY config config

# 3. Source code
COPY lib lib
COPY priv priv
COPY scripts scripts

# 5. Compile and make release
RUN MIX_ENV=$mix_env mix compile
RUN MIX_ENV=$mix_env mix release

# ============================================
# Stage 4: Runtime (production – minimal image)
# ============================================
FROM alpine:3.20 AS app

RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++ \
    ca-certificates \
    && rm -rf /var/cache/apk/*

ARG mix_env=prod
WORKDIR /app

RUN addgroup -g 1000 -S appuser && \
    adduser -u 1000 -S appuser -G appuser && \
    chown -R appuser:appuser /app

USER appuser:appuser

COPY --from=build --chown=appuser:appuser /app/_build/${mix_env}/rel/api_token_pool ./
COPY --from=build --chown=appuser:appuser /app/scripts/start.sh ./start.sh

ENV HOME=/app \
    PATH=/app/bin:$PATH

CMD ["sh", "./start.sh"]
