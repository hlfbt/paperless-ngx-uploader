#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Detect Docker/Podman (prefer functional docker, then podman)
if [ -z "$DOCKER_BIN" ]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        DOCKER_BIN="docker"
    elif command -v podman >/dev/null 2>&1; then
        DOCKER_BIN="podman"
    else
        DOCKER_BIN="docker"
    fi
fi

# Detect Compose (prefer plugin 'docker compose', then 'podman-compose', then 'docker-compose')
if [ -z "$COMPOSE_CMD" ]; then
    if $DOCKER_BIN compose version >/dev/null 2>&1; then
        COMPOSE_CMD="$DOCKER_BIN compose"
    elif command -v podman-compose >/dev/null 2>&1; then
        COMPOSE_CMD="podman-compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        echo -e "${RED}Error: No compose provider found for $DOCKER_BIN.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Using binary: $DOCKER_BIN${NC}"
echo -e "${GREEN}Using compose: $COMPOSE_CMD${NC}"

# Optional build (only if Dockerfile is present in context and user wants to build)
if [ "$1" == "--build" ]; then
    echo -e "${GREEN}Building uploader image as localhost/uploader:test...${NC}"
    $DOCKER_BIN build -t localhost/uploader:test uploader
fi

cleanup() {
    echo -e "${GREEN}Cleaning up...${NC}"
    $COMPOSE_CMD -f tests/docker-compose.test.yml down -v
    rm -rf tests/integration-data/*
}

run_test_scenario() {
    local scenario=$1
    echo -e "${GREEN}--- Running scenario: $scenario ---${NC}"
    
    # Reset integration data
    rm -rf tests/integration-data/*
    mkdir -p tests/integration-data/consumption tests/integration-data/archive
    chmod 777 tests/integration-data/consumption tests/integration-data/archive

    # Start environment
    export API_UPLOADER_ON_SUCCESS=$scenario
    $COMPOSE_CMD -f tests/docker-compose.test.yml up -d
    
    # Wait for services to be ready
    echo "Waiting for services to start..."
    sleep 15

    # Trigger upload
    local test_file="test_document_$scenario.pdf"
    echo "test content" > "tests/integration-data/consumption/$test_file"
    echo "Copied $test_file to consumption directory."

    # Wait for processing
    echo "Waiting for processing..."
    sleep 15

    # Verify Mock API received the file
    echo "Verifying API received the file..."
    received_files=$(curl -s http://localhost:8080/received)
    if [[ "$received_files" == *"$test_file"* ]]; then
        echo -e "${GREEN}PASS: Mock API received $test_file${NC}"
    else
        echo -e "${RED}FAIL: Mock API did not receive $test_file${NC}"
        echo "Received files log:"
        echo "$received_files"
        $COMPOSE_CMD -f tests/docker-compose.test.yml logs uploader
        exit 1
    fi

    # Verify Post-upload action
    if [ "$scenario" = "delete" ]; then
        if [ ! -f "tests/integration-data/consumption/$test_file" ]; then
            echo -e "${GREEN}PASS: File was deleted from consumption directory.${NC}"
        else
            echo -e "${RED}FAIL: File was NOT deleted from consumption directory.${NC}"
            exit 1
        fi
    elif [ "$scenario" = "archive" ]; then
        archive_count=$(ls tests/integration-data/archive/*$test_file 2>/dev/null | wc -l)
        if [ "$archive_count" -gt 0 ]; then
            echo -e "${GREEN}PASS: File was moved to archive directory.${NC}"
        else
            echo -e "${RED}FAIL: File was NOT found in archive directory.${NC}"
            exit 1
        fi
    fi

    $COMPOSE_CMD -f tests/docker-compose.test.yml down -v
}

# Run tests
run_test_scenario "delete"
run_test_scenario "archive"

echo -e "${GREEN}ALL INTEGRATION TESTS PASSED!${NC}"
