#!/bin/bash

#############################################
# MapleStory AutoBot Performance Profiler
# Uses py-spy to generate flame graph
#############################################

# Default values
CONFIG_FILE="config/config_custom.yaml"
DURATION=30

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --config FILE     Configuration file (default: config/config_custom.yaml)"
    echo "  --duration SECONDS Sampling duration in seconds (default: 30)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --config config/config_default.yaml --duration 60"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}[ERROR] Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Trap signals for cleanup
trap cleanup EXIT INT TERM

BOT_PID=""
cleanup() {
    if [[ -n "$BOT_PID" ]]; then
        echo -e "\n${YELLOW}Stopping MapleStory AutoBot...${NC}"
        kill $BOT_PID 2>/dev/null
        wait $BOT_PID 2>/dev/null
    fi
}

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}MapleStory AutoBot Performance Profiler${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if py-spy is installed
if ! python -c "import py_spy" 2>/dev/null; then
    echo -e "${YELLOW}[INFO] Installing py-spy...${NC}"
    pip install py-spy
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[ERROR] Failed to install py-spy${NC}"
        exit 1
    fi
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}[ERROR] Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}[1/3] Starting MapleStory AutoBot...${NC}"
echo "    Config: $CONFIG_FILE"
python -m src.main --config "$CONFIG_FILE" &
BOT_PID=$!

if [[ -z "$BOT_PID" ]]; then
    echo -e "${RED}[ERROR] Failed to start MapleStory AutoBot${NC}"
    exit 1
fi

echo "    PID: $BOT_PID"
echo ""
echo "Waiting for program to start..."
sleep 5

# Check if process is still running
if ! kill -0 $BOT_PID 2>/dev/null; then
    echo -e "${RED}[ERROR] MapleStory AutoBot process died unexpectedly${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}[2/3] Starting py-spy profiling...${NC}"
echo "    Duration: ${DURATION}s"
echo "    Output: profile.svg"
echo ""

# Run py-spy
py-spy record --pid $BOT_PID --output profile.svg --duration $DURATION

if [[ -f profile.svg ]]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}SUCCESS! Profile saved to profile.svg${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Open profile.svg in your browser to see:"
    echo "  - Which functions consume the most CPU"
    echo "  - The complete call stack"
    echo "  - Performance bottlenecks"
    echo ""

    # Try to open in browser
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open profile.svg
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open profile.svg 2>/dev/null || firefox profile.svg 2>/dev/null || google-chrome profile.svg 2>/dev/null
    fi
else
    echo -e "${RED}[ERROR] Failed to generate profile.svg${NC}"
    exit 1
fi
