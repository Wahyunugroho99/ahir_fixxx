#!/bin/bash

# Test script for n8n Video Summarizer Webhook
# Usage: ./test-webhook.sh

# Configuration
N8N_WEBHOOK_URL="https://your-n8n-instance.com/webhook/video-summarizer-webhook"
GOOGLE_DRIVE_FOLDER_ID="your-google-drive-folder-id"
TELEGRAM_CHAT_ID="your-telegram-chat-id"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Testing n8n Video Summarizer Webhook${NC}"
echo "==============================================="

# Check if required tools are installed
command -v curl >/dev/null 2>&1 || { echo -e "${RED}❌ curl is required but not installed.${NC}" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${YELLOW}⚠️ jq not found. JSON response won't be formatted.${NC}"; }

# Validate configuration
if [[ "$N8N_WEBHOOK_URL" == *"your-n8n-instance"* ]]; then
    echo -e "${RED}❌ Please update N8N_WEBHOOK_URL with your actual n8n instance URL${NC}"
    exit 1
fi

if [[ "$GOOGLE_DRIVE_FOLDER_ID" == *"your-google-drive"* ]]; then
    echo -e "${RED}❌ Please update GOOGLE_DRIVE_FOLDER_ID with your actual folder ID${NC}"
    exit 1
fi

if [[ "$TELEGRAM_CHAT_ID" == *"your-telegram"* ]]; then
    echo -e "${RED}❌ Please update TELEGRAM_CHAT_ID with your actual chat ID${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuration validated${NC}"
echo "Webhook URL: $N8N_WEBHOOK_URL"
echo "Google Drive Folder ID: $GOOGLE_DRIVE_FOLDER_ID"
echo "Telegram Chat ID: $TELEGRAM_CHAT_ID"
echo ""

# Prepare test payload
TEST_PAYLOAD=$(cat <<EOF
{
  "folderId": "$GOOGLE_DRIVE_FOLDER_ID",
  "telegramChatId": "$TELEGRAM_CHAT_ID",
  "testMode": true,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

echo -e "${YELLOW}📤 Sending test request...${NC}"
echo "Payload:"
echo "$TEST_PAYLOAD" | jq '.' 2>/dev/null || echo "$TEST_PAYLOAD"
echo ""

# Send webhook request
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\nTIME_TOTAL:%{time_total}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "User-Agent: n8n-video-summarizer-test/1.0" \
  -d "$TEST_PAYLOAD" \
  "$N8N_WEBHOOK_URL")

# Extract HTTP status and response time
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
TIME_TOTAL=$(echo "$RESPONSE" | grep "TIME_TOTAL:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d' | sed '/TIME_TOTAL:/d')

echo -e "${YELLOW}📥 Response received:${NC}"
echo "HTTP Status: $HTTP_STATUS"
echo "Response Time: ${TIME_TOTAL}s"
echo ""

# Check response status
case $HTTP_STATUS in
    200)
        echo -e "${GREEN}✅ SUCCESS: Webhook accepted (HTTP 200)${NC}"
        ;;
    201)
        echo -e "${GREEN}✅ SUCCESS: Workflow triggered (HTTP 201)${NC}"
        ;;
    400)
        echo -e "${RED}❌ BAD REQUEST: Invalid payload (HTTP 400)${NC}"
        ;;
    401)
        echo -e "${RED}❌ UNAUTHORIZED: Authentication failed (HTTP 401)${NC}"
        ;;
    404)
        echo -e "${RED}❌ NOT FOUND: Webhook URL not found (HTTP 404)${NC}"
        ;;
    500)
        echo -e "${RED}❌ SERVER ERROR: n8n internal error (HTTP 500)${NC}"
        ;;
    *)
        echo -e "${YELLOW}⚠️ UNEXPECTED: HTTP $HTTP_STATUS${NC}"
        ;;
esac

echo ""
echo "Response Body:"
if command -v jq >/dev/null 2>&1; then
    echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo "$RESPONSE_BODY"
fi

echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Check n8n workflow execution log"
echo "2. Verify Google Drive folder access"
echo "3. Monitor Telegram for delivered report"
echo "4. Check n8n instance logs if errors occur"

# Performance check
if (( $(echo "$TIME_TOTAL > 30" | bc -l) )); then
    echo -e "${YELLOW}⚠️ Response time is high (${TIME_TOTAL}s). Consider optimizing workflow.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Test completed!${NC}"