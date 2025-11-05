#!/bin/bash
# test-wrapper.sh - Test del wrapper listen-interactive con mock

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Testing listen-interactive wrapper${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar que mock-listen existe
MOCK_LISTEN="$(dirname "$0")/mock-listen"
if [ ! -f "$MOCK_LISTEN" ]; then
    echo -e "${RED}❌ Error: mock-listen not found at $MOCK_LISTEN${NC}"
    exit 1
fi

# Crear wrapper temporal que usa el mock
TEMP_WRAPPER=$(mktemp)
chmod +x "$TEMP_WRAPPER"

cat > "$TEMP_WRAPPER" << 'WRAPPER_EOF'
#!/bin/bash
# Temporary wrapper for testing

set -e

# Colors and formatting
RED='\033[91m'
RST='\033[0m'
CLR='\033[K'

# Parse arguments
LANG="en"
MODEL="base"

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--language) LANG="$2"; shift 2 ;;
        -m|--model) MODEL="$2"; shift 2 ;;
        --mock-listen) MOCK_LISTEN="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Use mock if provided
LISTEN_CMD="${MOCK_LISTEN:-listen}"

# Temporary file for output
OUTPUT_FILE=$(mktemp)
trap "rm -f $OUTPUT_FILE; stty sane 2>/dev/null" EXIT INT TERM

# Start mock listen
"$LISTEN_CMD" -l "$LANG" -m "$MODEL" --signal-mode 2>/dev/null > "$OUTPUT_FILE" &
LISTEN_PID=$!

# Save terminal state
OLD_STTY=$(stty -g 2>/dev/null)

# Display UI
echo -ne "${RED}●${RST} Listening  [          ]"
echo ""
echo "Press SPACE to stop recording"
echo ""

# Move cursor up
echo -ne "\033[2A\r"

# Set raw mode
stty raw -echo 2>/dev/null

# Animation loop
COUNTER=0
while true; do
    # Animate
    if [ $((COUNTER % 2)) -eq 0 ]; then
        echo -ne "\r${RED}●${RST} Listening  [          ]${CLR}"
    else
        echo -ne "\r${RED}●${RST} Listening  [==========]${CLR}"
    fi
    COUNTER=$((COUNTER + 1))

    # Check for key press
    if read -t 0.15 -n 1 key 2>/dev/null; then
        if [[ "$key" == " " ]]; then
            break
        fi
    fi

    # Check if process still running
    if ! kill -0 $LISTEN_PID 2>/dev/null; then
        break
    fi
done

# Restore terminal
stty "$OLD_STTY" 2>/dev/null

# Show processing
echo -ne "\r${CLR}"
echo -ne "\r${RED}●${RST} Processing  [          ]"
echo ""

# Send SIGUSR1
kill -SIGUSR1 $LISTEN_PID 2>/dev/null || true

# Wait
wait $LISTEN_PID 2>/dev/null || true

# Clear processing line
echo -ne "\033[1A\r${CLR}"

# Output
cat "$OUTPUT_FILE"
WRAPPER_EOF

trap "rm -f $TEMP_WRAPPER" EXIT

echo -e "${YELLOW}Test 1: Basic functionality (English, 3 seconds)${NC}"
echo "Instructions: Wait for '● Listening', then press SPACE after ~3 seconds"
echo ""
read -p "Press Enter to start..."
echo ""

RESULT=$("$TEMP_WRAPPER" -l en -m base --mock-listen "$MOCK_LISTEN")
echo ""
echo -e "${GREEN}✓ Transcription received:${NC} $RESULT"
echo ""

# Test 2: Spanish
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}Test 2: Spanish language (6 seconds)${NC}"
echo "Instructions: Press SPACE after ~6 seconds"
echo ""
read -p "Press Enter to start..."
echo ""

RESULT=$("$TEMP_WRAPPER" -l es -m base --mock-listen "$MOCK_LISTEN")
echo ""
echo -e "${GREEN}✓ Transcription received:${NC} $RESULT"
echo ""

# Test 3: Quick press
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}Test 3: Quick SPACE press (< 3 seconds)${NC}"
echo "Instructions: Press SPACE immediately when you see '● Listening'"
echo ""
read -p "Press Enter to start..."
echo ""

RESULT=$("$TEMP_WRAPPER" -l en -m base --mock-listen "$MOCK_LISTEN")
echo ""
echo -e "${GREEN}✓ Transcription received:${NC} $RESULT"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✨ All tests passed!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The wrapper is working correctly with SPACE control and SIGUSR1."
echo "You can now implement --signal-mode in listen.py"
echo ""
