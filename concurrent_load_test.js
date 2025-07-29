#!/usr/bin/env node

const http = require('http');

// Configuration
const TOTAL_EVENTS = parseInt(process.argv[2]) || 1000;
const CONCURRENT_REQUESTS = parseInt(process.argv[3]) || 50; // High concurrency
const VECTOR_URL = 'http://localhost:8080/collect';

console.log('🚀 CONCURRENT NODE.JS LOAD TEST');
console.log('===============================');
console.log(`📊 Total Events: ${TOTAL_EVENTS}`);
console.log(`⚡ Concurrent Requests: ${CONCURRENT_REQUESTS}`);
console.log('');

// Create HTTP agent with high concurrency settings
const agent = new http.Agent({
    keepAlive: true,
    keepAliveMsecs: 1000,
    maxSockets: CONCURRENT_REQUESTS * 2,
    maxFreeSockets: CONCURRENT_REQUESTS,
    timeout: 1000
});

function sendEvent(eventId) {
    return new Promise((resolve) => {
        const event = {
            event: 'Concurrent Test Event',
            userId: `user_${eventId}`,
            id: eventId,
            timestamp: Date.now()
        };

        const postData = JSON.stringify(event);
        
        const options = {
            hostname: 'localhost',
            port: 8080,
            path: '/collect',
            method: 'POST',
            agent: agent,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData),
                'Connection': 'keep-alive'
            }
        };

        const startTime = process.hrtime.bigint();
        
        const req = http.request(options, (res) => {
            // We must consume the response body for the connection to be reused
            res.on('data', () => {});
            res.on('end', () => {
                const duration = Number(process.hrtime.bigint() - startTime) / 1000000; // ms
                resolve({ 
                    success: res.statusCode === 200, 
                    statusCode: res.statusCode,
                    duration: duration,
                    eventId: eventId
                });
            });
        });

        req.on('error', (error) => {
            const duration = Number(process.hrtime.bigint() - startTime) / 1000000;
            resolve({ 
                success: false, 
                error: error.message,
                duration: duration,
                eventId: eventId
            });
        });

        req.write(postData);
        req.end();
    });
}

async function runConcurrentBatch(startId, batchSize) {
    const promises = [];
    
    // Create batch of concurrent requests
    for (let i = 0; i < batchSize; i++) {
        promises.push(sendEvent(startId + i));
    }
    
    // Wait for all requests in batch to complete
    return Promise.all(promises);
}

async function runLoadTest() {
    console.log('📤 Starting concurrent load test...');
    
    const overallStartTime = process.hrtime.bigint();
    const results = [];
    let successCount = 0;
    let errorCount = 0;
    
    // Send events in concurrent batches
    for (let i = 0; i < TOTAL_EVENTS; i += CONCURRENT_REQUESTS) {
        const batchSize = Math.min(CONCURRENT_REQUESTS, TOTAL_EVENTS - i);
        const batchStartTime = process.hrtime.bigint();
        
        const batchResults = await runConcurrentBatch(i + 1, batchSize);
        const batchDuration = Number(process.hrtime.bigint() - batchStartTime) / 1000000000; // seconds
        
        // Process batch results
        for (const result of batchResults) {
            results.push(result);
            if (result.success) {
                successCount++;
            } else {
                errorCount++;
                if (errorCount <= 5) {
                    console.log(`❌ Event ${result.eventId}: ${result.error || `HTTP ${result.statusCode}`}`);
                }
            }
        }
        
        const eventsProcessed = i + batchSize;
        const batchRate = Math.round(batchSize / batchDuration);
        const overallElapsed = Number(process.hrtime.bigint() - overallStartTime) / 1000000000;
        const overallRate = Math.round(eventsProcessed / overallElapsed);
        
        console.log(`📊 Batch ${Math.ceil(eventsProcessed / CONCURRENT_REQUESTS)}: ${batchSize} events in ${batchDuration.toFixed(3)}s (${batchRate} events/sec) | Overall: ${overallRate} events/sec`);
    }
    
    const totalDuration = Number(process.hrtime.bigint() - overallStartTime) / 1000000000;
    const eventsPerSecond = Math.round(TOTAL_EVENTS / totalDuration);
    
    // Calculate latency statistics
    const latencies = results.filter(r => r.success).map(r => r.duration);
    latencies.sort((a, b) => a - b);
    const avgLatency = latencies.reduce((sum, lat) => sum + lat, 0) / latencies.length;
    const p95Latency = latencies[Math.floor(latencies.length * 0.95)];
    const p99Latency = latencies[Math.floor(latencies.length * 0.99)];
    
    console.log('');
    console.log('🏁 CONCURRENT LOAD TEST RESULTS');
    console.log('===============================');
    console.log(`⏱️  Total Duration: ${totalDuration.toFixed(3)}s`);
    console.log(`📊 Total Events: ${TOTAL_EVENTS}`);
    console.log(`✅ Success: ${successCount}`);
    console.log(`❌ Errors: ${errorCount}`);
    console.log(`🚀 Events/Second: ${eventsPerSecond}`);
    console.log(`⚡ Concurrent Requests: ${CONCURRENT_REQUESTS}`);
    console.log('');
    console.log('📈 LATENCY STATISTICS:');
    console.log(`   Average: ${avgLatency.toFixed(2)}ms`);
    console.log(`   95th percentile: ${p95Latency.toFixed(2)}ms`);
    console.log(`   99th percentile: ${p99Latency.toFixed(2)}ms`);
    console.log('');
    
    if (eventsPerSecond < 1000) {
        console.log('⚠️  WARNING: Performance below 1000 events/sec indicates bottleneck');
    } else if (eventsPerSecond < 5000) {
        console.log('⚡ GOOD: Performance above 1K events/sec, approaching target');
    } else {
        console.log('🎯 EXCELLENT: High-performance target achieved!');
    }
    
    agent.destroy();
}

runLoadTest().catch(console.error); 