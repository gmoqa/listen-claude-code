#!/bin/bash
# quick-test.sh - Quick verification that mock-listen responds to SIGUSR1

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

MOCK="$(dirname "$0")/mock-listen"

if [ ! -x "$MOCK" ]; then
    echo -e "${RED}❌ mock-listen not found or not executable${NC}"
    exit 1
fi

echo -e "${YELLOW}Quick Test: SIGUSR1 handling${NC}"
echo ""

# Start mock in background
echo "Starting mock-listen..."
"$MOCK" -l en -m base --signal-mode > /tmp/mock-output.txt 2>&1 &
PID=$!

echo "PID: $PID"
echo "Waiting 2 seconds..."
sleep 2

echo "Sending SIGUSR1..."
kill -SIGUSR1 $PID

echo "Waiting for process to finish..."
wait $PID
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Process exited cleanly (code 0)${NC}"
else
    echo -e "${RED}✗ Process exited with code $EXIT_CODE${NC}"
    exit 1
fi

OUTPUT=$(cat /tmp/mock-output.txt)
if [ -n "$OUTPUT" ]; then
    echo -e "${GREEN}✓ Output received:${NC} $OUTPUT"
else
    echo -e "${RED}✗ No output received${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✨ Mock is working correctly!${NC}"
echo "You can now run: ./test-wrapper.sh"
