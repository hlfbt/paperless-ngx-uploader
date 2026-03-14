#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Detect Docker/Podman
if [ -z "$DOCKER_BIN" ]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        DOCKER_BIN="docker"
    elif command -v podman >/dev/null 2>&1; then
        DOCKER_BIN="podman"
    else
        DOCKER_BIN="docker"
    fi
fi

# Detect Compose
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

# Optional build
if [ "$1" == "--build" ]; then
    echo -e "${GREEN}Building full flavor as localhost/uploader:full-test...${NC}"
    $DOCKER_BIN build --build-arg FLAVOR=full -t localhost/uploader:full-test uploader
    echo -e "${GREEN}Building lightweight flavor as localhost/uploader:lightweight-test...${NC}"
    $DOCKER_BIN build --build-arg FLAVOR=lightweight -t localhost/uploader:lightweight-test uploader
fi

# Function to run the lightweight test scenarios
run_lightweight_test() {
    local scenario=$1
    echo -e "${GREEN}--- Running Lightweight scenario: $scenario ---${NC}"
    
    # Setup data
    rm -rf tests/integration-data/*
    mkdir -p tests/integration-data/consumption tests/integration-data/archive
    chmod -R 777 tests/integration-data

    # Start environment
    export API_UPLOADER_ON_SUCCESS=$scenario
    $COMPOSE_CMD -f tests/docker-compose.lightweight.test.yml up -d
    
    # Wait for services
    echo "Waiting for services to start..."
    sleep 5

    local test_file="lightweight_doc_$scenario.pdf"
    echo "test content for $scenario" > "tests/integration-data/consumption/$test_file"
    echo "Dropped $test_file into consumption directory."

    # Wait for processing
    echo "Waiting for processing..."
    sleep 10

    # Verify Mock API received the file
    echo "Verifying API received the file..."
    received_files=$(curl -s http://localhost:8080/received)
    if [[ "$received_files" == *"$test_file"* ]]; then
        echo -e "${GREEN}PASS: Mock API received $test_file${NC}"
    else
        echo -e "${RED}FAIL: Mock API did not receive $test_file${NC}"
        echo "Received files log:"
        echo "$received_files"
        $COMPOSE_CMD -f tests/docker-compose.lightweight.test.yml logs uploader
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

    $COMPOSE_CMD -f tests/docker-compose.lightweight.test.yml down -v
}

# Function to run the full flavor smoke test
run_full_smoke_test() {
    echo -e "${GREEN}--- Running Full Flavor Smoke Test ---${NC}"
    
    # Setup data
    rm -rf tests/integration-data/*
    mkdir -p tests/integration-data/consumption tests/integration-data/archive
    chmod -R 777 tests/integration-data

    # Start environment
    $COMPOSE_CMD -f tests/docker-compose.full.test.yml up -d
    
    # Wait and check health
    echo "Waiting for full flavor to start..."
    sleep 15

    # Check if container is still running
    if [ "$( $DOCKER_BIN inspect -f '{{.State.Running}}' paperless-uploader-full-test 2>/dev/null )" == "true" ]; then
        echo -e "${GREEN}PASS: Full flavor container is running.${NC}"
    else
        echo -e "${RED}FAIL: Full flavor container failed to start or crashed.${NC}"
        $COMPOSE_CMD -f tests/docker-compose.full.test.yml logs uploader
        exit 1
    fi

    # Check if s6-overlay successfully started all services (by log)
    if $COMPOSE_CMD -f tests/docker-compose.full.test.yml logs uploader | grep -q "s6-rc: info: service s6rc-oneshot-runner successfully started"; then
        echo -e "${GREEN}PASS: s6-overlay finished startup.${NC}"
    else
        echo -e "${RED}FAIL: s6-overlay did not report successful startup in time.${NC}"
        $COMPOSE_CMD -f tests/docker-compose.full.test.yml logs uploader
        exit 1
    fi

    $COMPOSE_CMD -f tests/docker-compose.full.test.yml down -v
}

# Run tests
run_lightweight_test "delete"
run_lightweight_test "archive"
run_full_smoke_test

echo -e "${GREEN}ALL TESTS PASSED!${NC}"
