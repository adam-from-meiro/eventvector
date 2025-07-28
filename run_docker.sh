#!/bin/bash

# Stop and remove the old container if it exists, ignoring errors
docker stop vector-router >/dev/null 2>&1 || true
docker rm vector-router >/dev/null 2>&1 || true

# Replace with your actual PostHog Project API key
export POSTHOG_API_KEY="phc_VagDd3dMR555wFkntMxctlSfSspu1zLj6pJ2tlmxg07"
export MIXPANEL_HOST="https://eu.mixpanel.com/project/3810260"
export MIXPANEL_PROJECT="b201f844d80135e5d0f85b4d08a8dadd"
export MIXPANEL_TOKEN="704164ff05f7d786e9d06cfc73af6427"

docker run --name vector-router \
  -p 8080:8080 \
  -v "$(pwd)/vector.yaml:/etc/vector/vector.yaml:ro" \
  -e POSTHOG_API_KEY \
  -e MIXPANEL_HOST \
  -e MIXPANEL_PROJECT \
  -e MIXPANEL_TOKEN \
  timberio/vector:latest-debian

