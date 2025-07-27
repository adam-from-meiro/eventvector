# Vector-based Events Router with PostHog - Implementation Plan

## Executive Summary

This plan outlines the implementation of an Events Router using Vector to ingest marketing events (similar to Google Analytics) and forward them to PostHog for analytics and automation. PostHog's generous free tier (1M events/month) and instant API access make it perfect for MVP validation.

## Architecture Overview

```
[Web/App Clients] → HTTP POST → [Vector HTTP Server Source]
                                          ↓
                                 [VRL Transformation Layer]
                                          ↓
                                    [PostHog API]
```

## Why PostHog?

- **Instant Access**: Sign up and get API keys immediately
- **Generous Free Tier**: 1M events/month free forever
- **Developer-First**: Excellent API documentation
- **Open Source**: Can self-host later if needed
- **Built-in Features**: Analytics, feature flags, session replay, A/B testing
- **No Paperwork**: Zero approval process

## Phase 1: MVP Implementation (Week 1)

### Objectives
- Set up PostHog account and Vector instance
- Implement GA-compatible event ingestion
- Create transformation pipeline for PostHog
- Test end-to-end event flow

### Tasks

#### 1.1 PostHog Setup (Day 1)
- [ ] Sign up for PostHog Cloud (US or EU)
- [ ] Create first project
- [ ] Get Project API Key from Project Settings
- [ ] Review PostHog event structure documentation
- [ ] Install PostHog JS snippet on test site (optional)

#### 1.2 Vector Environment Setup (Day 1-2)
- [ ] Install Vector binary or containerize
- [ ] Set up configuration management
- [ ] Create development environment
- [ ] Configure environment variables

#### 1.3 Basic Vector Configuration (Day 2-3)
```yaml
# vector.yaml
sources:
  ga_events:
    type: http_server
    address: "0.0.0.0:8080"
    path: "/collect"
    method: "POST"
    encoding: "json"
    headers:
      - "User-Agent"
      - "X-Forwarded-For"

transforms:
  parse_and_validate:
    type: remap
    inputs: ["ga_events"]
    source: |
      # Validate required fields
      if !exists(.event) {
        abort
      }
      
      # Extract user identification
      .distinct_id = .userId || .user_id || .anonymousId || .session_id
      if !exists(.distinct_id) {
        .distinct_id = uuid_v4()
      }
      
      # Standardize timestamp
      .timestamp = .timestamp || now()
      
      # Map common GA parameters to PostHog properties
      .properties = .properties || {}
      if exists(.value) {
        .properties.value = .value
      }
      if exists(.category) {
        .properties.category = .category
      }
      if exists(.label) {
        .properties.label = .label
      }

  format_for_posthog:
    type: remap
    inputs: ["parse_and_validate"]
    source: |
      # Build PostHog capture event
      .posthog_event = {
        "api_key": env("POSTHOG_API_KEY"),
        "event": .event,
        "properties": .properties,
        "timestamp": format_timestamp!(.timestamp, "%+"),
        "distinct_id": .distinct_id
      }
      
      # Add optional fields
      if exists(.user_agent) {
        .posthog_event.properties."$user_agent" = .user_agent
      }
      if exists(.ip) {
        .posthog_event.properties."$ip" = .ip
      }
      if exists(.url) {
        .posthog_event.properties."$current_url" = .url
      }
      
      # Set final payload
      . = .posthog_event

sinks:
  posthog:
    type: http
    inputs: ["format_for_posthog"]
    uri: "https://app.posthog.com/capture/"
    method: "POST"
    encoding:
      codec: "json"
    batch:
      max_events: 100
      timeout_secs: 1
    request:
      retry_attempts: 3
      retry_initial_backoff_secs: 1
```

#### 1.4 Event Types to Support (Day 3-4)
- [ ] Page views
- [ ] Custom events (clicks, form submits)
- [ ] E-commerce events (add to cart, purchase)
- [ ] User identification events
- [ ] Session events

#### 1.5 Testing Suite (Day 4-5)
```bash
# Test script for common events
#!/bin/bash

# Page view
curl -X POST http://localhost:8080/collect \
  -H "Content-Type: application/json" \
  -d '{
    "event": "$pageview",
    "userId": "user123",
    "properties": {
      "$current_url": "https://example.com/products",
      "$referrer": "https://google.com"
    }
  }'

# E-commerce event
curl -X POST http://localhost:8080/collect \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Product Added",
    "userId": "user123",
    "properties": {
      "product_id": "SKU123",
      "product_name": "Test Product",
      "price": 29.99,
      "currency": "USD"
    }
  }'

# Custom event
curl -X POST http://localhost:8080/collect \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Button Clicked",
    "anonymousId": "anon456",
    "properties": {
      "button_name": "Sign Up",
      "page": "/home"
    }
  }'
```

### Deliverables
- Working Vector → PostHog pipeline
- Test suite with common event types
- Basic monitoring setup
- Documentation

## Phase 2: Enhanced Features (Week 2)

### Objectives
- Add advanced transformations
- Implement user identification/aliasing
- Add data enrichment
- Set up monitoring and alerting

### Tasks

#### 2.1 Advanced Transformations
```yaml
transforms:
  enrich_events:
    type: remap
    inputs: ["parse_and_validate"]
    source: |
      # Geo enrichment (if IP available)
      if exists(.ip) {
        .properties."$geoip_country_code" = geoip!(.ip, "country_code")
        .properties."$geoip_city_name" = geoip!(.ip, "city_name")
      }
      
      # User agent parsing
      if exists(.user_agent) {
        ua = parse_user_agent!(.user_agent)
        .properties."$browser" = ua.browser.family
        .properties."$browser_version" = ua.browser.version
        .properties."$os" = ua.os.family
        .properties."$device_type" = ua.device.family
      }
      
      # Session tracking
      if exists(.session_id) {
        .properties."$session_id" = .session_id
      }
      
      # UTM parameters
      if exists(.utm_source) {
        .properties."utm_source" = .utm_source
        .properties."utm_medium" = .utm_medium
        .properties."utm_campaign" = .utm_campaign
      }
```

#### 2.2 User Identification Handling
```yaml
transforms:
  handle_identify:
    type: remap
    inputs: ["enrich_events"]
    source: |
      # Special handling for identify events
      if .event == "$identify" || .event == "identify" {
        .posthog_event = {
          "api_key": env("POSTHOG_API_KEY"),
          "event": "$identify",
          "distinct_id": .distinct_id,
          "properties": {
            "$set": .traits || .properties || {}
          }
        }
      }
      
      # Handle alias events (linking anonymous to identified users)
      if .event == "$create_alias" || .event == "alias" {
        .posthog_event = {
          "api_key": env("POSTHOG_API_KEY"),
          "event": "$create_alias",
          "distinct_id": .distinct_id,
          "properties": {
            "alias": .alias || .previousId
          }
        }
      }
```

#### 2.3 Monitoring Setup
- [ ] Vector internal metrics endpoint
- [ ] PostHog ingestion monitoring
- [ ] Error tracking and alerting
- [ ] Performance dashboards

#### 2.4 Multi-Environment Support
```yaml
transforms:
  add_environment:
    type: remap
    inputs: ["source"]
    source: |
      .properties.environment = env("ENVIRONMENT") || "production"
      
      # Route to different PostHog projects based on environment
      if .properties.environment == "staging" {
        .api_key = env("POSTHOG_STAGING_API_KEY")
      } else {
        .api_key = env("POSTHOG_PROD_API_KEY")
      }
```

## Phase 3: Production Deployment (Week 3)

### Objectives
- Production infrastructure setup
- High availability configuration
- Performance optimization
- Documentation and training

### Tasks

#### 3.1 Infrastructure Setup
- [ ] Deploy Vector in production (Kubernetes/Docker)
- [ ] Configure autoscaling
- [ ] Set up load balancing
- [ ] Implement health checks

#### 3.2 Reliability Features
```yaml
sinks:
  posthog_primary:
    type: http
    inputs: ["format_for_posthog"]
    uri: "https://app.posthog.com/capture/"
    buffer:
      type: disk
      max_size: 268435488  # 256MB
      when_full: block
    request:
      retry_attempts: 5
      retry_max_duration_secs: 30
      rate_limit_num: 1000
      rate_limit_duration_secs: 1
      timeout_secs: 30
      
  # Dead letter queue for failed events
  failed_events:
    type: file
    inputs: ["posthog_primary.dropped"]
    path: "/var/log/vector/failed_events.log"
    encoding:
      codec: "json"
```

#### 3.3 Performance Optimization
- [ ] Benchmark with expected load (10K events/sec)
- [ ] Optimize VRL transformations
- [ ] Configure batching and compression
- [ ] Tune resource allocation

#### 3.4 Migration Strategy
- [ ] Parallel run with existing system
- [ ] Traffic splitting (10% → 50% → 100%)
- [ ] Validation of event data in PostHog
- [ ] Rollback procedures

## Phase 4: Advanced PostHog Integration (Week 4)

### Objectives
- Leverage PostHog's advanced features
- Set up automated workflows
- Implement feature flags integration
- Create custom dashboards

### Tasks

#### 4.1 PostHog Feature Integration
- [ ] Set up Cohorts based on events
- [ ] Create Insights and Dashboards
- [ ] Configure Actions (event-based triggers)
- [ ] Implement Feature Flags for A/B testing

#### 4.2 Webhook Integration
```yaml
# Add PostHog webhook source for bi-directional flow
sources:
  posthog_webhooks:
    type: http_server
    address: "0.0.0.0:8081"
    path: "/webhooks/posthog"
    
transforms:
  process_webhooks:
    type: remap
    inputs: ["posthog_webhooks"]
    source: |
      # Process PostHog webhooks (e.g., feature flag changes)
      if .type == "feature_flag_updated" {
        # Trigger downstream actions
      }
```

#### 4.3 Export to Data Warehouse
- [ ] Set up PostHog data export
- [ ] Configure Vector to also write to S3/BigQuery
- [ ] Create data lake for long-term storage

## Cost Analysis

### PostHog Costs
- **Free Tier**: 1M events, 5K recordings, 1M feature flags/month
- **Estimated Monthly**: $0 for MVP, ~$200-500 at scale
- **No hidden fees**: Transparent pricing

### Infrastructure Costs
- **Vector Instance**: ~$50-100/month (single instance)
- **Load Balancer**: ~$20/month
- **Storage**: ~$10/month for buffering
- **Total**: ~$80-130/month for infrastructure

## Success Metrics

### Technical KPIs
- Event ingestion rate: 10K+ events/sec
- Latency: < 100ms p95
- Success rate: > 99.9%
- Zero data loss

### Business KPIs
- Time to implement new event types: < 1 hour
- Developer onboarding time: < 30 minutes
- Cost per million events: < $10
- Feature adoption rate via PostHog analytics

## Migration Checklist

### Week 1: MVP
- [ ] PostHog account setup
- [ ] Basic Vector configuration
- [ ] Test event ingestion
- [ ] Verify data in PostHog

### Week 2: Enhancement
- [ ] Add enrichment
- [ ] Implement monitoring
- [ ] Load testing
- [ ] Documentation

### Week 3: Production
- [ ] Deploy infrastructure
- [ ] Configure HA
- [ ] Performance tuning
- [ ] Gradual rollout

### Week 4: Integration
- [ ] PostHog features
- [ ] Automation setup
- [ ] Training
- [ ] Full migration

## Quick Start Commands

```bash
# 1. Set environment variables
export POSTHOG_API_KEY="phc_your_project_api_key"
export ENVIRONMENT="development"

# 2. Run Vector with config
vector --config vector.yaml

# 3. Test event ingestion
curl -X POST http://localhost:8080/collect \
  -H "Content-Type: application/json" \
  -d '{"event": "Test Event", "userId": "test123"}'

# 4. Check PostHog dashboard
# Navigate to app.posthog.com → Events
```

## Next Steps

1. Create PostHog account (5 minutes)
2. Set up development Vector instance (30 minutes)
3. Test basic event flow (1 hour)
4. Plan production deployment (1 day)
5. Begin migration (1 week)

This simplified plan focusing on PostHog reduces complexity while maintaining all the benefits of the Vector-based approach. The instant API access and generous free tier make it perfect for rapid MVP development and validation.