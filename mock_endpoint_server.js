#!/usr/bin/env node

const http = require('http');

// Configuration - support command line arguments
const PORT = process.env.PORT || 9090;
const SIMULATED_LATENCY_MS = process.argv.includes('--no-latency') ? 0 : 
                             (process.env.LATENCY ? parseInt(process.env.LATENCY) : 100);
const EXPECTED_BATCH_SIZE = 10000;

let requestCount = 0;
let totalEvents = 0;
let startTime = Date.now();

const server = http.createServer(async (req, res) => {
  requestCount++;
  
  if (req.method !== 'POST') {
    res.writeHead(405, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Method not allowed' }));
    return;
  }

  // Collect request body
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', async () => {
    const requestStart = Date.now();
    
    try {
      // Parse the events (could be single event or array)
      let events;
      try {
        const parsed = JSON.parse(body);
        events = Array.isArray(parsed) ? parsed : [parsed];
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
        return;
      }
      
      totalEvents += events.length;
      
      // Simulate processing latency
      if (SIMULATED_LATENCY_MS > 0) {
        await new Promise(resolve => setTimeout(resolve, SIMULATED_LATENCY_MS));
      }
      
      const processingTime = Date.now() - requestStart;
      const uptime = (Date.now() - startTime) / 1000;
      const eventsPerSecond = Math.round(totalEvents / uptime);
      
      // Log performance metrics every 1000 requests or large batches
      if (requestCount % 1000 === 0 || events.length >= 1000) {
        console.log(`📊 Request #${requestCount}: ${events.length} events, ${processingTime}ms processing, ${eventsPerSecond} events/sec total`);
      }
      
      // Respond with success and metrics
      res.writeHead(200, { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      });
      
      res.end(JSON.stringify({
        success: true,
        events_received: events.length,
        processing_time_ms: processingTime,
        request_id: requestCount,
        total_events: totalEvents,
        events_per_second: eventsPerSecond,
        uptime_seconds: Math.round(uptime)
      }));
      
    } catch (error) {
      console.error('❌ Error processing request:', error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Internal server error' }));
    }
  });
});

// Handle server startup
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Mock Endpoint Server started on port ${PORT}`);
  if (SIMULATED_LATENCY_MS === 0) {
    console.log(`⚡ RAW PERFORMANCE MODE: No artificial latency`);
  } else {
    console.log(`⏱️  Simulated latency: ${SIMULATED_LATENCY_MS}ms`);
  }
  console.log(`📦 Expected batch size: ${EXPECTED_BATCH_SIZE} events`);
  console.log(`🔗 Endpoint: http://localhost:${PORT}/batch`);
  console.log('');
  if (SIMULATED_LATENCY_MS === 0) {
    console.log('Ready for RAW PERFORMANCE testing! ⚡🎯');
  } else {
    console.log('Ready for performance testing! 🎯');
  }
});

// Graceful shutdown
process.on('SIGINT', () => {
  const uptime = (Date.now() - startTime) / 1000;
  console.log('\n📊 Final Performance Stats:');
  console.log(`   Total Requests: ${requestCount}`);
  console.log(`   Total Events: ${totalEvents}`);
  console.log(`   Uptime: ${Math.round(uptime)}s`);
  if (uptime > 0) {
    console.log(`   Average Events/sec: ${Math.round(totalEvents / uptime)}`);
  }
  console.log('👋 Shutting down gracefully...');
  server.close(() => {
    process.exit(0);
  });
});

module.exports = server; 