#!/bin/bash
# auto-test.sh - Automated test without user interaction

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

MOCK="$(dirname "$0")/mock-listen"

echo -e "${YELLOW}Automated Test: Full wrapper simulation${NC}"
echo ""

# Test 1: Simulate 2 second recording
echo "Test 1: 2 second recording (English)"
"$MOCK" -l en -m base --signal-mode > /tmp/test1.txt &
PID=$!
sleep 2
kill -SIGUSR1 $PID
wait $PID
RESULT=$(cat /tmp/test1.txt)
if [[ "$RESULT" == "Hello Claude" ]]; then
    echo -e "${GREEN}✓ Test 1 passed${NC}"
else
    echo -e "${RED}✗ Test 1 failed: got '$RESULT'${NC}"
    exit 1
fi
echo ""

# Test 2: Simulate 5 second recording with Spanish
echo "Test 2: 5 second recording (Spanish)"
"$MOCK" -l es -m base --signal-mode > /tmp/test2.txt &
PID=$!
sleep 5
kill -SIGUSR1 $PID
wait $PID
RESULT=$(cat /tmp/test2.txt)
if [[ "$RESULT" == "Muéstrame los archivos Python en este directorio" ]]; then
    echo -e "${GREEN}✓ Test 2 passed${NC}"
else
    echo -e "${RED}✗ Test 2 failed: got '$RESULT'${NC}"
    exit 1
fi
echo ""

# Test 3: Simulate quick stop (< 1 second)
echo "Test 3: Immediate stop"
"$MOCK" -l en -m base --signal-mode > /tmp/test3.txt &
PID=$!
sleep 0.5
kill -SIGUSR1 $PID
wait $PID
RESULT=$(cat /tmp/test3.txt)
if [[ "$RESULT" == "Hello Claude" ]]; then
    echo -e "${GREEN}✓ Test 3 passed${NC}"
else
    echo -e "${RED}✗ Test 3 failed: got '$RESULT'${NC}"
    exit 1
fi
echo ""

# Test 4: Test with different model
echo "Test 4: Different model (medium)"
"$MOCK" -l en -m medium --signal-mode > /tmp/test4.txt &
PID=$!
sleep 3
kill -SIGUSR1 $PID
wait $PID
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Test 4 passed (exit code 0)${NC}"
else
    echo -e "${RED}✗ Test 4 failed (exit code $EXIT_CODE)${NC}"
    exit 1
fi
echo ""

# Cleanup
rm -f /tmp/test*.txt

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✨ All automated tests passed!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Mock is working correctly. Next steps:"
echo "1. Run ./test-wrapper.sh for interactive UI test"
echo "2. Implement --signal-mode in listen.py"
echo "3. Test with real listen command"
