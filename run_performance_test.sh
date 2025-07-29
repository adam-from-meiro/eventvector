#!/bin/bash

# Vector Performance Test Runner
# Orchestrates the complete performance testing setup

set -e  # Exit on any error

# --- Configuration ---
DEFAULT_EVENTS=10000
DEFAULT_WORKERS=50
DEFAULT_LOAD_GENERATOR="node" # 'node' or 'bash'

# --- Argument Parsing ---
EVENTS=$DEFAULT_EVENTS
WORKERS=$DEFAULT_WORKERS
NO_LATENCY=false
LOAD_GENERATOR=$DEFAULT_LOAD_GENERATOR
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-latency)
      NO_LATENCY=true
      shift
      ;;
    --events)
      EVENTS="$2"
      shift 2
      ;;
    --workers)
      WORKERS="$2"
      shift 2
      ;;
    --generator)
      LOAD_GENERATOR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --events N         Number of total events to send (default: $DEFAULT_EVENTS)"
      echo "  --workers N        Number of concurrent workers/requests (default: $DEFAULT_WORKERS)"
      echo "  --no-latency       Run mock server without artificial 100ms latency"
      echo "  --generator TYPE   Specify load generator: 'node' (default) or 'bash'"
      echo "  -h, --help         Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                                   # Realistic test: 10k events, 50 workers, 100ms latency"
      echo "  $0 --events 50000 --workers 200      # High-load realistic test"
      echo "  $0 --no-latency                      # Raw performance test with no latency"
      echo "  $0 --generator bash --events 1000    # Use legacy bash generator for a small test"
      exit 0
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# --- Main Script ---
echo "🎯 VECTOR PERFORMANCE TEST SUITE"
echo "================================="
echo "📊 Events: $EVENTS"
echo "👥 Workers: $WORKERS"
echo "🤖 Generator: $LOAD_GENERATOR"

if [[ "$NO_LATENCY" == "true" ]]; then
  echo "⚡ Mode: RAW PERFORMANCE (no artificial latency)"
else
  echo "⏱️  Mode: REALISTIC (100ms latency simulation)"
fi
echo ""

# --- Prerequisite Checks ---
echo "🔍 Checking prerequisites..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js."
    exit 1
fi
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker."
    exit 1
fi
chmod +x ./*.js
echo "✅ Prerequisites check passed"
echo ""

# --- Cleanup Function ---
cleanup_and_exit() {
    local exit_code=${1:-0}
    echo ""
    echo "🧹 Cleaning up..."
    # Kill mock server and Vector container
    kill $MOCK_SERVER_PID 2>/dev/null || true
    docker stop vector-router 2>/dev/null || true
    docker rm vector-router 2>/dev/null || true
    echo "✅ Cleanup completed"
    exit $exit_code
}
trap 'cleanup_and_exit 130' INT TERM

# --- Test Execution ---

# 1. Start Mock Server
if [[ "$NO_LATENCY" == "true" ]]; then
  echo "🚀 Step 1: Starting Mock Endpoint Server (RAW PERFORMANCE MODE)"
  node mock_endpoint_server.js --no-latency &
else
  echo "🚀 Step 1: Starting Mock Endpoint Server (100ms latency simulation)"
  node mock_endpoint_server.js &
fi
MOCK_SERVER_PID=$!
sleep 2
echo "✅ Mock server is running (PID: $MOCK_SERVER_PID)"
echo ""

# 2. Start Vector
echo "🚀 Step 2: Starting Vector with Performance Configuration"
docker run --name vector-router \
  -p 8080:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v "$(pwd)/vector-performance-test.yaml:/etc/vector/vector.yaml:ro" \
  -d timberio/vector:latest-debian
sleep 5
echo "✅ Vector is running and accepting connections"
echo ""

# 3. Run Load Test
echo "🚀 Step 3: Running Performance Load Test"
echo "💡 Watch the Mock Server console for real-time batch processing stats"
echo ""

START_TIME=$(date +%s)

if [[ "$LOAD_GENERATOR" == "node" ]]; then
  node concurrent_load_test.js "$EVENTS" "$WORKERS"
else
  # Note: The bash generator is inefficient and kept for legacy/comparison purposes.
  echo "⚠️  WARNING: Using inefficient 'bash' load generator."
  ./performance_load_test.sh "$EVENTS" "$WORKERS" "$NO_LATENCY"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# --- Results ---
echo ""
echo "📊 FINAL RESULTS"
echo "======================="
echo "⏱️  Total Test Duration: ${DURATION}s"
echo ""
echo "📈 CHECK RESULTS:"
echo "   - See throughput and latency stats from the script output above."
echo "   - Mock Server Console: Shows real-time batch processing stats."
echo "   - Vector Logs: docker logs vector-router"
echo ""

# --- Cleanup ---
cleanup_and_exit 0 