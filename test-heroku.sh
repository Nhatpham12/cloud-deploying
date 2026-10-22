#!/bin/bash
# test-heroku.sh  (usage: ./test-heroku.sh [gateway-url])
# Default targets the local gateway; pass your Heroku URL to test the deployment.

GATEWAY_URL="${1:-http://localhost:3000}"

pp() { if command -v jq >/dev/null; then jq .; else cat; echo; fi; }

echo "Testing API Gateway..."
curl -s "$GATEWAY_URL/" | pp

echo -e "\n\nTesting health checks..."
curl -s "$GATEWAY_URL/health" | pp

echo -e "\n\nTesting Users service..."
curl -s "$GATEWAY_URL/users" | pp

echo -e "\n\nCreating new user..."
curl -s -X POST "$GATEWAY_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User", "email": "test@heroku.com"}' | pp

echo -e "\n\nTesting Products service..."
curl -s "$GATEWAY_URL/products" | pp

echo -e "\n\nCreating new product..."
curl -s -X POST "$GATEWAY_URL/products" \
  -H "Content-Type: application/json" \
  -d '{"name": "Heroku Product", "price": 50, "stock": 100}' | pp

echo -e "\n\nCreating order..."
curl -s -X POST "$GATEWAY_URL/orders" \
  -H "Content-Type: application/json" \
  -d '{"userId": 1, "productId": 1, "quantity": 2}' | pp

echo -e "\n\nGetting all orders..."
curl -s "$GATEWAY_URL/orders" | pp
