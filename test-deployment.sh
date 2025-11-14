#!/bin/bash

# PDF2AudioBook Deployment Testing Script
# This script helps you test your Render deployment

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "PDF2AudioBook - Deployment Testing"
echo "=========================================="
echo ""

# Get URLs from user
read -p "Enter your BACKEND URL (e.g., https://pdf2audiobook-api.onrender.com): " BACKEND_URL
read -p "Enter your FRONTEND URL (e.g., https://pdf2audiobook.onrender.com): " FRONTEND_URL

echo ""
echo -e "${BLUE}Testing deployment...${NC}"
echo ""

# Test 1: Backend Health Check
echo -e "${YELLOW}[Test 1/6]${NC} Testing Backend Health..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BACKEND_URL/health" || echo "error")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} Backend is reachable (HTTP $HTTP_CODE)"

    # Parse JSON response
    if echo "$HEALTH_BODY" | grep -q '"status"'; then
        STATUS=$(echo "$HEALTH_BODY" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        echo -e "  Status: $STATUS"

        # Check dependencies
        if echo "$HEALTH_BODY" | grep -q '"database"'; then
            DB_STATUS=$(echo "$HEALTH_BODY" | grep -o '"database":"[^"]*"' | cut -d'"' -f4)
            if [ "$DB_STATUS" = "healthy" ]; then
                echo -e "  ${GREEN}✓${NC} Database: $DB_STATUS"
            else
                echo -e "  ${RED}✗${NC} Database: $DB_STATUS"
            fi
        fi

        if echo "$HEALTH_BODY" | grep -q '"redis"'; then
            REDIS_STATUS=$(echo "$HEALTH_BODY" | grep -o '"redis":"[^"]*"' | cut -d'"' -f4)
            if [ "$REDIS_STATUS" = "healthy" ]; then
                echo -e "  ${GREEN}✓${NC} Redis: $REDIS_STATUS"
            else
                echo -e "  ${RED}✗${NC} Redis: $REDIS_STATUS"
            fi
        fi

        if echo "$HEALTH_BODY" | grep -q '"s3"'; then
            S3_STATUS=$(echo "$HEALTH_BODY" | grep -o '"s3":"[^"]*"' | cut -d'"' -f4)
            if [ "$S3_STATUS" = "healthy" ] || [ "$S3_STATUS" = "not_configured" ]; then
                echo -e "  ${GREEN}✓${NC} S3: $S3_STATUS"
            else
                echo -e "  ${RED}✗${NC} S3: $S3_STATUS"
            fi
        fi
    fi
else
    echo -e "${RED}✗${NC} Backend health check failed (HTTP $HTTP_CODE)"
    echo "  Response: $HEALTH_BODY"
fi
echo ""

# Test 2: API Documentation
echo -e "${YELLOW}[Test 2/6]${NC} Testing API Documentation..."
DOCS_RESPONSE=$(curl -s -w "\n%{http_code}" "$BACKEND_URL/docs" || echo "error")
DOCS_HTTP_CODE=$(echo "$DOCS_RESPONSE" | tail -n1)

if [ "$DOCS_HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} API docs accessible at: $BACKEND_URL/docs"
else
    echo -e "${RED}✗${NC} API docs not accessible (HTTP $DOCS_HTTP_CODE)"
fi
echo ""

# Test 3: Frontend Accessibility
echo -e "${YELLOW}[Test 3/6]${NC} Testing Frontend..."
FRONTEND_RESPONSE=$(curl -s -w "\n%{http_code}" "$FRONTEND_URL" || echo "error")
FRONTEND_HTTP_CODE=$(echo "$FRONTEND_RESPONSE" | tail -n1)

if [ "$FRONTEND_HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} Frontend is accessible (HTTP $FRONTEND_HTTP_CODE)"
else
    echo -e "${RED}✗${NC} Frontend not accessible (HTTP $FRONTEND_HTTP_CODE)"
fi
echo ""

# Test 4: CORS Configuration
echo -e "${YELLOW}[Test 4/6]${NC} Testing CORS Configuration..."
CORS_RESPONSE=$(curl -s -H "Origin: $FRONTEND_URL" -H "Access-Control-Request-Method: POST" -X OPTIONS "$BACKEND_URL/api/v1/auth/me" -i || echo "error")

if echo "$CORS_RESPONSE" | grep -q "Access-Control-Allow-Origin"; then
    echo -e "${GREEN}✓${NC} CORS headers present"
    ALLOWED_ORIGIN=$(echo "$CORS_RESPONSE" | grep "Access-Control-Allow-Origin" | cut -d' ' -f2 | tr -d '\r')
    echo "  Allowed Origin: $ALLOWED_ORIGIN"
else
    echo -e "${YELLOW}⚠${NC} CORS headers not found"
    echo "  You may need to set CORS_ALLOW_ORIGINS=$FRONTEND_URL in backend environment"
fi
echo ""

# Test 5: Database Migration Status
echo -e "${YELLOW}[Test 5/6]${NC} Testing Database Tables..."
# This requires authentication, so we'll just remind the user
echo -e "${BLUE}ℹ${NC}  Manual check required:"
echo "  1. Go to Render Dashboard → Backend Service → Shell"
echo "  2. Run: cd backend && python -c 'from app.core.database import engine; from sqlalchemy import inspect; print(inspect(engine).get_table_names())'"
echo "  3. Verify tables exist: users, jobs, products, subscriptions, transactions"
echo ""

# Test 6: Worker Status
echo -e "${YELLOW}[Test 6/6]${NC} Testing Worker Status..."
echo -e "${BLUE}ℹ${NC}  Manual check required:"
echo "  1. Go to Render Dashboard → Worker Service → Logs"
echo "  2. Look for: 'celery@hostname ready'"
echo "  3. Verify no connection errors"
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "Backend URL: $BACKEND_URL"
echo "Frontend URL: $FRONTEND_URL"
echo ""
echo "Next Steps:"
echo "1. Check the results above"
echo "2. If all tests pass, proceed with manual testing"
echo "3. Upload a test PDF through the frontend"
echo "4. Monitor worker logs for processing"
echo "5. Verify audio file is generated"
echo ""
echo "For detailed testing checklist, see:"
echo "  RENDER_DEPLOYMENT_STATUS.md"
echo ""
echo "=========================================="
