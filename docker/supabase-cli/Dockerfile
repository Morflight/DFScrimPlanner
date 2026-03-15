FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz \
    | tar -xz -C /usr/local/bin supabase && \
    rm -rf /var/lib/apt/lists/*
