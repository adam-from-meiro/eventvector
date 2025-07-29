# Vector Events Router

A high-performance events router built with [Vector](https://vector.dev) that intelligently routes marketing and analytics events to multiple destinations with zero data loss.

## 🎯 What It Does

This system acts as a **smart events router** that:
- **Ingests events** via HTTP API (Google Analytics-compatible)
- **Intelligently routes** events based on their purpose:
  - 🔵 **Marketing events** → PostHog (attribution, campaigns, growth)
  - 🟠 **Analytics events** → Mixpanel (user behavior, product analytics)
- **Dual routing** for overlapping events (e.g., purchases sent to both platforms)
- **Zero data loss** with buffering, retries, and error handling

## 🏗️ Architecture

```
[Web/App Clients] 
       ↓ HTTP POST
[Vector HTTP Server :8080]
       ↓ VRL Transforms
[Intelligent Event Router]
       ↓         ↓
   [PostHog]  [Mixpanel]
  (Marketing) (Analytics)
```

### Core Components

1. **HTTP Source** - Accepts events on `/collect` endpoint
2. **VRL Transforms** - Parse, validate, and enrich events
3. **Intelligent Router** - Routes events based on type and properties
4. **Dual Sinks** - PostHog and Mixpanel integrations
5. **Error Handling** - Retries, buffering, and monitoring

## 🚀 Quick Start

### Prerequisites
- Docker installed and running
- PostHog account and API key
- Mixpanel account and project token

### 1. Clone and Setup
```bash
git clone <your-repo>
cd eventsvector

# Set your API keys in run_docker.sh
export POSTHOG_API_KEY="phc_your_posthog_key"
export MIXPANEL_TOKEN="your_mixpanel_token"
```

### 2. Start Vector
```bash
./run_docker.sh
```

### 3. Test the Integration
```bash
./events_test.sh
```

### 4. Send Your First Event
```bash
curl -X POST "http://localhost:8080/collect" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Sign Up",
    "userId": "user123",
    "properties": {
      "Country": "United States",
      "OS": "macOS",
      "Source": "Website"
    }
  }'
```

## 📊 Event Routing Logic

### PostHog (Marketing Focus)
Events routed to PostHog for **marketing attribution and growth analytics**:

- ✅ **User Identification** (`$identify`) - User profiles and attribution  
- ✅ **UTM Campaigns** - Any event with `utm_source` parameter
- ✅ **Purchase Attribution** - Purchase events with UTM parameters
- ✅ **Session Tracking** - Session start/end events

**Example PostHog Event:**
```json
{
  "event": "$identify",
  "userId": "user123",
  "traits": {
    "$name": "John Doe",
    "$email": "john@example.com"
  }
}
```

### Mixpanel (Analytics Focus)  
Events routed to Mixpanel for **product analytics and user behavior**:

- ✅ **Sign Up** - User registration events
- ✅ **Page View** - Page navigation tracking
- ✅ **Request Demo** - Lead generation events
- ✅ **User Profiles** - Profile updates via `/engage` endpoint

**Example Mixpanel Event:**
```json
{
  "event": "Sign Up",
  "userId": "user123", 
  "properties": {
    "Country": "United States",
    "OS": "Web",
    "Source": "Google Ads"
  }
}
```

### Dual Routing
Some events go to **both platforms** with different focus:
- **Purchase Events**: PostHog (marketing attribution) + Mixpanel (product analytics)
- **User Identification**: PostHog (growth) + Mixpanel (behavioral segmentation)

## 🔧 Configuration

### Environment Variables
Set these in `run_docker.sh`:
```bash
export POSTHOG_API_KEY="phc_your_key_here"
export MIXPANEL_TOKEN="your_token_here"
export MIXPANEL_PROJECT="your_project_id"
```

### Event Types Configuration
Events are automatically routed based on the `event` field:

| Event Name | PostHog | Mixpanel | Purpose |
|------------|---------|----------|---------|
| `$identify` | ✅ | ✅ | User identification |
| `Sign Up` | ❌ | ✅ | Product analytics |
| `Page View` | ❌ | ✅ | Navigation tracking |
| `Request Demo` | ❌ | ✅ | Lead generation |
| `Purchase` (with UTM) | ✅ | ❌ | Marketing attribution |
| `Purchase` (no UTM) | ❌ | ✅ | Product analytics |

### Vector Configuration
Main configuration in `vector.yaml`:
- **HTTP Source**: Listens on port 8080
- **Transforms**: Parse, validate, route events
- **Sinks**: PostHog and Mixpanel integrations
- **Batching**: Optimized for performance
- **Retries**: 3 attempts with exponential backoff

## 📡 API Reference

### Endpoint
```
POST http://localhost:8080/collect
Content-Type: application/json
```

### Event Schema
```json
{
  "event": "Event Name",           // Required: Event type
  "userId": "user123",             // User identifier  
  "timestamp": "2025-01-28T12:00:00Z", // Optional: Event time
  "properties": {                  // Optional: Event properties
    "key": "value"
  },
  "traits": {                      // For identify events
    "$name": "John Doe",
    "$email": "john@example.com"
  }
}
```

### Response
```json
HTTP 200 OK
```

## 🎯 Supported Event Types

### Marketing Events (→ PostHog)
```javascript
// User identification
{
  "event": "$identify",
  "userId": "user123",
  "traits": { "$name": "John", "$email": "john@email.com" }
}

// Campaign attribution  
{
  "event": "Purchase",
  "userId": "user123",
  "properties": { "value": 99.99, "utm_source": "google" }
}
```

### Product Analytics Events (→ Mixpanel)
```javascript
// User registration
{
  "event": "Sign Up", 
  "userId": "user123",
  "properties": { "Country": "US", "OS": "Web", "Source": "Organic" }
}

// Feature usage
{
  "event": "Page View",
  "userId": "user123", 
  "properties": { "Page Name": "Dashboard", "Referrer URL Path": "/login" }
}

// Lead generation
{
  "event": "Request Demo",
  "userId": "user123",
  "properties": { "Contact Method": "Form", "Area of Interest": "Enterprise" }
}
```

## 🔍 Monitoring & Debugging

### Check Vector Status
```bash
docker logs vector-router
```

### Test Event Processing
```bash
./events_test.sh
```

### Monitor Dashboards
- **PostHog**: https://app.posthog.com → Events
- **Mixpanel**: https://mixpanel.com/report/events

## 📈 Performance

The router is designed for high-throughput, low-latency event processing.

### Benchmarks
- **Raw Performance**: **20,000+ events/second** with sub-10ms latency (p95). This measures the maximum throughput of Vector without network delays.
- **Realistic Performance**: **~5,000-10,000 events/second** when simulating a downstream API with 100ms latency.
- **Resources**: Uses <100MB of memory and <50% of a single CPU core under typical load.

### Performance Testing
This project includes a comprehensive performance testing suite to validate these numbers in your own environment.

**Quick Start**
```bash
# Run a high-load raw performance test (20k+ events/sec)
./run_performance_test.sh --events 50000 --workers 200 --no-latency

# Run a realistic test with simulated 100ms downstream latency
./run_performance_test.sh --events 10000 --workers 50

# See all options
./run_performance_test.sh --help
```

**Test Modes**
-   **Raw Performance (`--no-latency`)**: Benchmarks the maximum speed of the router by removing downstream latency. Use this to assess pure processing power.
-   **Realistic Mode (Default)**: Simulates a 100ms API latency to measure performance under real-world conditions.

For more details on the test setup, see the `run_performance_test.sh` script and its components.

### Scaling
- **Horizontal**: Run multiple Vector instances behind a load balancer.
- **Vertical**: Increase Docker container resources (CPU/memory).
- **Batching**: Tune batch sizes in `vector.yaml` to match the latency profile of your downstream APIs.

## 🔐 Security

### API Security
- Run behind reverse proxy with authentication
- Use HTTPS in production
- Implement rate limiting

### Data Privacy
- Events are processed in memory only
- No persistent storage of event data
- GDPR-compliant with proper user consent

## 📚 Additional Documentation

- **[Performance Testing](PERFORMANCE_TEST_README.md)** - Load testing with realistic conditions and raw performance benchmarking
- **[Vector Documentation](https://vector.dev/docs/)** - Official Vector docs
- **[PostHog API](https://posthog.com/docs/api)** - PostHog integration details  
- **[Mixpanel API](https://docs.mixpanel.com/docs/tracking-best-practices)** - Mixpanel integration guide

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes with `./events_test.sh`
4. Run performance tests:
   - Realistic: `./run_performance_test.sh` 
   - Raw performance: `./run_performance_test.sh --no-latency`
5. Submit a pull request

## 📄 License

[Add your license information here]

---

**Built with ❤️ using [Vector](https://vector.dev) for intelligent event routing** 