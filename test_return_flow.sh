#!/bin/bash

# Test ReturnSaleItem endpoint routing
# This script tests if the route /api/Sales/{saleId}/return-item works correctly

BASE_URL="http://localhost:5137"
TOKEN=""

echo "=== Testing ReturnSaleItem Routing ==="
echo ""

# Step 1: Create test user and get token
echo "Step 1: Creating test user..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/Test/create-user" \
  -H "Content-Type: application/json" \
  -d '{"username":"returnflowtest","password":"test123"}')

echo "User creation response: $RESPONSE"

# Extract token from response (assuming it returns JSON with accessToken)
TOKEN=$(echo $RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "ERROR: Could not get token. Response: $RESPONSE"
  exit 1
fi

echo "Token obtained: ${TOKEN:0:50}..."
echo ""

# Step 2: Create a market for the user
echo "Step 2: Creating market..."
MARKET_RESPONSE=$(curl -s -X POST "$BASE_URL/api/Markets/RegisterMarket" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Test Market","subdomain":"testmarket","description":"Test market for return flow"}')

echo "Market creation response: $MARKET_RESPONSE"
echo ""

# Step 3: Create a product
echo "Step 3: Creating product..."
PRODUCT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/Products/CreateProduct" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Test Product","costPrice":10000,"salePrice":15000,"minSalePrice":12000,"quantity":20,"minThreshold":5}')

echo "Product creation response: $PRODUCT_RESPONSE"

# Extract product ID
PRODUCT_ID=$(echo $PRODUCT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Product ID: $PRODUCT_ID"
echo ""

# Step 4: Create a sale
echo "Step 4: Creating sale..."
SALE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/Sales/CreateSale" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{}')

echo "Sale creation response: $SALE_RESPONSE"

# Extract sale ID
SALE_ID=$(echo $SALE_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Sale ID: $SALE_ID"
echo ""

# Step 5: Add items to sale (6 items)
echo "Step 5: Adding 6 items to sale..."
ADD_ITEM_RESPONSE=$(curl -s -X POST "$BASE_URL/api/Sales/AddSaleItem/$SALE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"productId\":\"$PRODUCT_ID\",\"quantity\":6,\"salePrice\":15000,\"minSalePrice\":12000,\"comment\":\"\"}")

echo "Add item response: $ADD_ITEM_RESPONSE"

# Extract sale item ID
SALE_ITEM_ID=$(echo $ADD_ITEM_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Sale Item ID: $SALE_ITEM_ID"
echo ""

# Step 6: Add payment
echo "Step 6: Adding payment..."
PAYMENT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/Sales/AddPayment/$SALE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"paymentType":"cash","amount":90000}')

echo "Payment response: $PAYMENT_RESPONSE"
echo ""

# Step 7: Get sale details before return
echo "Step 7: Getting sale details before return..."
BEFORE_SALE=$(curl -s -X GET "$BASE_URL/api/Sales/GetSale/$SALE_ID" \
  -H "Authorization: Bearer $TOKEN")

echo "Sale before return:"
echo $BEFORE_SALE | jq '.'
echo ""

# Step 8: Return 1 item - THIS IS THE KEY TEST
echo "Step 8: Returning 1 item..."
echo "Calling: POST $BASE_URL/api/Sales/$SALE_ID/return-item"
echo ""

RETURN_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BASE_URL/api/Sales/$SALE_ID/return-item" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"saleItemId\":\"$SALE_ITEM_ID\",\"quantity\":1,\"comment\":\"Test return\"}")

echo "Return response:"
echo $RETURN_RESPONSE
echo ""

# Extract HTTP status
HTTP_STATUS=$(echo "$RETURN_RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
RETURN_BODY=$(echo "$RETURN_RESPONSE" | sed '/HTTP_STATUS:/d')

echo "HTTP Status: $HTTP_STATUS"
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✓ SUCCESS! Return endpoint returned 200"

  # Step 9: Get sale details after return
  echo ""
  echo "Step 9: Getting sale details after return..."
  AFTER_SALE=$(curl -s -X GET "$BASE_URL/api/Sales/GetSale/$SALE_ID" \
    -H "Authorization: Bearer $TOKEN")

  echo "Sale after return:"
  echo $AFTER_SALE | jq '.'

  # Extract quantity before and after
  QTY_BEFORE=$(echo $BEFORE_SALE | jq '.saleItems[0].quantity')
  QTY_AFTER=$(echo $AFTER_SALE | jq '.saleItems[0].quantity')

  echo ""
  echo "=== VERIFICATION ==="
  echo "Quantity before: $QTY_BEFORE"
  echo "Quantity after: $QTY_AFTER"

  if [ "$QTY_AFTER" = "5" ]; then
    echo "✓ QUANTITY UPDATED CORRECTLY (6 → 5)"
  else
    echo "✗ ERROR: Quantity not updated correctly"
  fi
else
  echo "✗ ERROR! Return endpoint returned $HTTP_STATUS"
  echo "Response body: $RETURN_BODY"
fi

echo ""
echo "=== Test Complete ==="
