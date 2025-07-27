#!/bin/bash

# Stop and remove the old container if it exists, ignoring errors
docker stop vector-router >/dev/null 2>&1 || true
docker rm vector-router >/dev/null 2>&1 || true

# Replace with your actual PostHog Project API key
export POSTHOG_API_KEY="phc_VagDd3dMR555wFkntMxctlSfSspu1zLj6pJ2tlmxg07"

docker run --name vector-router \
  -p 8080:8080 \
  -v "$(pwd)/vector.yaml:/etc/vector/vector.yaml:ro" \
  -e POSTHOG_API_KEY \
  timberio/vector:latest-debian

