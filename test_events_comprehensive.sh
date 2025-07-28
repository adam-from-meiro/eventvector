#!/bin/bash

# Dual Routing Test Suite - Marketing → PostHog, Analytics → Mixpanel
echo "🚀 Testing DUAL ROUTING Vector Pipeline"
echo "📊 Marketing Events → PostHog | Analytics Events → Mixpanel"
echo "=================================================================="

# Base URL for Vector HTTP server
VECTOR_URL="http://localhost:8080/collect"

echo ""
echo "🔵 MARKETING EVENTS → PostHog (Attribution & Growth)"
echo "===================================================="

echo ""
echo "1.1 📄 Page View → PostHog (Marketing Attribution)"
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
  -w "\nStatus: %{http_code} → PostHog\n"

echo ""
echo "1.2 👤 User Identification → PostHog (Marketing Profiles)"
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
  -w "\nStatus: %{http_code} → PostHog\n"

echo ""
echo "1.3 🎯 Session Started → PostHog (Marketing Sessions)"
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
    },
    "utm_source": "facebook",
    "utm_campaign": "brand_awareness"
  }' \
  -w "\nStatus: %{http_code} → PostHog\n"

echo ""
echo "1.4 📧 Newsletter Signup → PostHog (Marketing Conversion)"
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
    "utm_content": "cta_button"
  }' \
  -w "\nStatus: %{http_code} → PostHog\n"

echo ""
echo "🟠 ANALYTICS EVENTS → Mixpanel (Product & User Behavior)"
echo "========================================================"

echo ""
echo "2.1 🖱️ Button Click → Mixpanel (Interaction Analytics)"
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
  -w "\nStatus: %{http_code} → Mixpanel\n"

echo ""
echo "2.2 📝 Form Submission → Mixpanel (Conversion Analytics)"
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
  -w "\nStatus: %{http_code} → Mixpanel\n"

echo ""
echo "2.3 🛒 Product Added → Mixpanel (E-commerce Analytics)"
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
  -w "\nStatus: %{http_code} → Mixpanel\n"

echo ""
echo "2.4 ⚡ Feature Usage → Mixpanel (Product Analytics)"
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
  -w "\nStatus: %{http_code} → Mixpanel\n"

echo ""
echo "🟣 OVERLAP EVENTS → BOTH DESTINATIONS (Dual Analytics)"
echo "====================================================="

echo ""
echo "3.1 💰 Purchase (Marketing Attribution) → PostHog"
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
      "payment_method": "credit_card",
      "utm_campaign": "summer_sale"
    }
  }' \
  -w "\nStatus: %{http_code} → PostHog (has UTM)\n"

echo ""
echo "3.2 💰 Purchase (Product Analytics) → Mixpanel"
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Purchase",
    "userId": "user456",
    "properties": {
      "order_id": "ORD789",
      "total": 299.99,
      "currency": "USD",
      "products": [
        {"product_id": "SKU789", "price": 299.99}
      ],
      "payment_method": "paypal",
      "checkout_step": "final"
    }
  }' \
  -w "\nStatus: %{http_code} → Mixpanel (no UTM)\n"

echo ""
echo "🔄 ROUTING LOGIC DEMONSTRATION"
echo "=============================="

echo ""
echo "4.1 📄 Event with UTM → PostHog (Marketing Focus)"
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "Custom Event",
    "userId": "user999",
    "properties": {
      "action": "demo_request"
    },
    "utm_source": "twitter",
    "utm_campaign": "product_launch"
  }' \
  -w "\nStatus: %{http_code} → PostHog (UTM present)\n"

echo ""
echo "4.2 🖱️ Event with 'Click' → Mixpanel (Analytics Focus)" 
curl -X POST "$VECTOR_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "CTA Click",
    "userId": "user888",
    "properties": {
      "cta_text": "Get Started",
      "page": "/landing"
    }
  }' \
  -w "\nStatus: %{http_code} → Mixpanel (contains 'Click')\n"

echo ""
echo "✅ DUAL ROUTING TEST COMPLETE!"
echo "=============================="
echo ""
echo "📊 ROUTING SUMMARY:"
echo "🔵 PostHog (Marketing):    Page views, User ID, Sessions, UTM events"
echo "🟠 Mixpanel (Analytics):   Clicks, Forms, Products, Features"  
echo "🟣 Both Platforms:         Purchase events (different focus)"
echo ""
echo "🔍 CHECK YOUR DASHBOARDS:"
echo "📊 PostHog:  https://app.posthog.com → Activity → Events"
echo "📈 Mixpanel: https://mixpanel.com/report/events → Live View"
echo ""
echo "🏷️  EVENT PROPERTIES ADDED:"
echo "   • event_category: 'marketing' | 'analytics'"
echo "   • destination: 'posthog' | 'mixpanel'"
echo "   • interaction_type: 'click' | 'form' | 'feature_usage'"  
echo "   • ecommerce_action: 'add_to_cart' | 'purchase'"
echo "   • attribution_focus: true (for UTM purchases)" 