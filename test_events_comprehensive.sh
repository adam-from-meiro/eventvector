#!/bin/bash

# Comprehensive Event Testing Suite - All Event Types from Plan
echo "🚀 Testing Enhanced Vector → PostHog Event Pipeline"
echo "Testing all event types: Page Views, Custom Events, E-commerce, User ID, Sessions"

# Base URL for Vector HTTP server
VECTOR_URL="http://localhost:8080/collect"

echo ""
echo "=== 1. PAGE VIEW EVENTS ==="

echo "1.1 Testing Basic Page View..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  -H "X-Forwarded-For: 192.168.1.100" \
  -H "Referer: https://google.com/search" \
  -d '{
    "event": "$pageview",
    "userId": "user123",
    "url": "https://mystore.com/products",
    "properties": {
      "page_title": "Products Page",
      "section": "catalog"
    },
    "utm_source": "google",
    "utm_medium": "cpc",
    "utm_campaign": "summer_sale"
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "1.2 Testing Page View with Session..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)" \
  -d '{
    "event": "pageview",
    "anonymousId": "anon789",
    "session_id": "sess_abc123",
    "url": "https://mystore.com/checkout",
    "properties": {
      "page_title": "Checkout",
      "step": "payment"
    }
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "=== 2. E-COMMERCE EVENTS ==="

echo "2.1 Testing Product Added to Cart..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
  -d '{
    "event": "Product Added",
    "userId": "user123",
    "properties": {
      "product_id": "SKU123",
      "product_name": "Wireless Headphones",
      "price": 89.99,
      "currency": "USD",
      "category": "Electronics",
      "brand": "TechBrand"
    }
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "2.2 Testing Purchase Completed..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Purchase",
    "userId": "user123",
    "properties": {
      "order_id": "ORD456",
      "total": 189.98,
      "currency": "USD",
      "products": [
        {"product_id": "SKU123", "price": 89.99},
        {"product_id": "SKU456", "price": 99.99}
      ],
      "payment_method": "credit_card"
    }
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "=== 3. CUSTOM EVENTS (Interactions) ==="

echo "3.1 Testing Button Click..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Button Clicked",
    "userId": "user456",
    "properties": {
      "button_name": "Sign Up Now",
      "page": "/pricing",
      "position": "header",
      "plan": "premium"
    }
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "3.2 Testing Form Submission..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Form Submitted",
    "anonymousId": "anon999",
    "properties": {
      "form_name": "contact_us",
      "form_type": "lead_generation",
      "page": "/contact",
      "fields": ["name", "email", "message"]
    }
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "=== 4. USER IDENTIFICATION EVENTS ==="

echo "4.1 Testing User Identification..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "$identify",
    "userId": "user123",
    "traits": {
      "email": "user123@example.com",
      "name": "John Smith",
      "plan": "premium",
      "company": "Acme Corp",
      "signup_date": "2025-01-15"
    }
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "=== 5. SESSION EVENTS ==="

echo "5.1 Testing Session Started..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
  -d '{
    "event": "Session Started",
    "anonymousId": "anon123",
    "session_id": "sess_xyz789",
    "properties": {
      "landing_page": "/home",
      "referrer_domain": "google.com",
      "device_type": "desktop"
    }
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "=== 6. MARKETING ATTRIBUTION (UTM) ==="

echo "6.1 Testing Event with Full UTM Parameters..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Newsletter Signup",
    "userId": "user789",
    "properties": {
      "newsletter_type": "weekly",
      "source_page": "/blog/article-1"
    },
    "utm_source": "facebook",
    "utm_medium": "social",
    "utm_campaign": "spring_newsletter",
    "utm_content": "cta_button",
    "utm_term": "email_marketing"
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "=== 7. CUSTOM EVENT WITH RICH PROPERTIES ==="

echo "7.1 Testing Feature Usage Event..."
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Feature Used",
    "userId": "user456",
    "properties": {
      "feature_name": "advanced_search",
      "usage_count": 5,
      "user_plan": "pro",
      "search_query": "wireless headphones",
      "results_count": 23,
      "time_spent": 45
    }
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "🎉 Comprehensive testing complete!"
echo ""
echo "📊 Check your PostHog dashboard for all event types:"
echo "   • Page Views ($pageview)"
echo "   • E-commerce (Product Added, Purchase)" 
echo "   • Custom Events (Button Clicked, Form Submitted)"
echo "   • User Identification ($identify)"
echo "   • Session Events (Session Started)"
echo "   • Custom Events (Newsletter Signup, Feature Used)"
echo ""
echo "🔍 Events should include PostHog system properties:"
echo "   • \$user_agent (from User-Agent header)"
echo "   • \$ip (from X-Forwarded-For header)"
echo "   • \$referrer (from Referer header)"
echo "   • \$current_url (from url field)"
echo "   • UTM parameters for attribution"
echo ""
echo "📍 PostHog Dashboard: https://app.posthog.com → Activity → Events" 