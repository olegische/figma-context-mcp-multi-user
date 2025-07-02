# Copyright Elasticsearch B.V. and contributors
# SPDX-License-Identifier: Apache-2.0
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:a0bd5b83ce1c3d1051a406cfe885af0268335452bb0454d07f2aba843b5b977f

RUN apk --no-cache add nodejs npm curl

WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm

# Install dependencies (Docker build cache friendly)
COPY package.json pnpm-lock.yaml tsconfig.json tsup.config.ts ./
COPY src/ ./src/
RUN pnpm install --no-frozen-lockfile

COPY run-docker.sh ./
RUN pnpm run build

# Future-proof the CLI and require the "stdio" argument
ENV RUNNING_IN_CONTAINER="true"

ENTRYPOINT ["./run-docker.sh"]
