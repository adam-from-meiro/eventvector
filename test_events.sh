#!/bin/bash

# Test script for Vector → PostHog event pipeline
echo "Testing Vector → PostHog Event Pipeline"

# Base URL for Vector HTTP server
VECTOR_URL="http://localhost:8080/collect"

echo ""
echo "1. Testing Page View Event..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  -H "X-Forwarded-For: 192.168.1.100" \
  -d '{
    "event": "$pageview",
    "userId": "user123",
    "url": "https://example.com/products",
    "properties": {
      "$current_url": "https://example.com/products",
      "$referrer": "https://google.com",
      "page_title": "Products Page"
    }
  }' \
  -w "\nStatus: %{http_code}\n\n"

echo "2. Testing Custom Event..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)" \
  -d '{
    "event": "Button Clicked",
    "anonymousId": "anon456",
    "properties": {
      "button_name": "Sign Up",
      "page": "/home",
      "category": "engagement"
    }
  }' \
  -w "\nStatus: %{http_code}\n\n"

echo "3. Testing E-commerce Event..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -d '{
    "event": "Product Added",
    "userId": "user789",
    "properties": {
      "product_id": "SKU123",
      "product_name": "Test Product",
      "price": 29.99,
      "currency": "USD",
      "value": 29.99
    }
  }' \
  -w "\nStatus: %{http_code}\n\n"

echo "4. Testing User Identification..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "$identify",
    "userId": "user123",
    "properties": {
      "email": "user@example.com",
      "name": "John Doe",
      "plan": "premium"
    }
  }' \
  -w "\nStatus: %{http_code}\n\n"

echo "5. Testing Event with Timestamp..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Custom Event",
    "userId": "user123",
    "timestamp": "2025-01-27T16:54:12.984Z",
    "properties": {
      "custom_property": "test_value"
    }
  }' \
  -w "\nStatus: %{http_code}\n\n"

echo "Testing complete! Check your PostHog dashboard at https://app.posthog.com for the events."
echo "Events should appear in: PostHog → Activity → Events" 