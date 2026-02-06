#!/bin/bash
#
# k8s-sherlock - Comprehensive Tool Test Suite
# Tests all installed tools in the Docker image.
#

set -euo pipefail

# ─────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────

IMAGE_NAME="k8s-sherlock-test"
CONTAINER_NAME="k8s-sherlock-test-$$"
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TEST_NUMBER=0
TEST_TIMEOUT=30
CI_MODE=false

# ─────────────────────────────────────────────
# CI Mode Detection
# ─────────────────────────────────────────────

for arg in "$@"; do
    if [ "$arg" = "--ci" ]; then
        CI_MODE=true
    fi
done

if [ "${CI:-}" = "true" ] || [ "${CI:-}" = "1" ]; then
    CI_MODE=true
fi

# ─────────────────────────────────────────────
# Colors (disabled in CI mode)
# ─────────────────────────────────────────────

if [ "$CI_MODE" = true ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
fi

# ─────────────────────────────────────────────
# Cleanup trap - always runs on exit
# ─────────────────────────────────────────────

cleanup() {
    echo ""
    echo -e "${BLUE}${BOLD}Cleaning up...${NC}"
    if [ -n "${CONTAINER_NAME:-}" ]; then
        if docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
            docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
        fi
    fi
    if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        docker rmi -f "$IMAGE_NAME" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ─────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────

run_in_container() {
    timeout "$TEST_TIMEOUT" docker exec "$CONTAINER_NAME" "$@" 2>&1
}

check_tool() {
    local name="$1"
    shift
    TEST_NUMBER=$((TEST_NUMBER + 1))
    if [ "$CI_MODE" = true ]; then
        if output=$(run_in_container "$@" 2>&1); then
            echo "ok $TEST_NUMBER - $name"
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            echo "not ok $TEST_NUMBER - $name"
            echo "#   $output" | head -3
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        printf "  %-25s" "$name"
        if output=$(run_in_container "$@" 2>&1); then
            echo -e "${GREEN}PASS${NC}"
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            echo -e "${RED}FAIL${NC}"
            echo -e "    ${RED}→ $output${NC}" | head -3
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
}

check_assert() {
    local name="$1"
    local actual="$2"
    local expected="$3"
    TEST_NUMBER=$((TEST_NUMBER + 1))
    if [ "$actual" = "$expected" ]; then
        if [ "$CI_MODE" = true ]; then
            echo "ok $TEST_NUMBER - $name"
        else
            printf "  %-25s" "$name"; echo -e "${GREEN}PASS${NC}"
        fi
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        if [ "$CI_MODE" = true ]; then
            echo "not ok $TEST_NUMBER - $name"
            echo "#   expected '$expected', got '$actual'"
        else
            printf "  %-25s" "$name"; echo -e "${RED}FAIL${NC}"
            echo -e "    ${RED}→ expected '$expected', got '$actual'${NC}"
        fi
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

section() {
    if [ "$CI_MODE" = true ]; then
        echo "# $1"
    else
        echo ""
        echo -e "${BLUE}${BOLD}── $1 ──${NC}"
    fi
}

# ─────────────────────────────────────────────
# Build image
# ─────────────────────────────────────────────

if [ "$CI_MODE" = true ]; then
    echo "TAP version 13"
fi

echo -e "${BOLD}k8s-sherlock Test Suite${NC}"
echo "=============================="

section "Building Docker image"
docker build -t "$IMAGE_NAME" . || {
    echo -e "${RED}Build failed. Aborting tests.${NC}"
    exit 1
}
echo -e "${GREEN}Image built successfully.${NC}"

# ─────────────────────────────────────────────
# Start container
# ─────────────────────────────────────────────

section "Starting test container"
docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep infinity || {
    echo -e "${RED}Failed to start container. Aborting tests.${NC}"
    exit 1
}
echo -e "${GREEN}Container started: $CONTAINER_NAME${NC}"

# ─────────────────────────────────────────────
# Non-Root User Verification
# ─────────────────────────────────────────────

section "Non-Root User Verification"

CONTAINER_USER=$(run_in_container id -un)
CONTAINER_UID=$(run_in_container id -u)

check_assert "user is sherlock"   "$CONTAINER_USER" "sherlock"
check_assert "uid is 999"         "$CONTAINER_UID"  "999"

# ─────────────────────────────────────────────
# Security Validation
# ─────────────────────────────────────────────

section "Security Validation"

check_assert "user is sherlock (security)" "$CONTAINER_USER" "sherlock"
check_assert "uid is 999 (security)"      "$CONTAINER_UID"  "999"

# Verify /home/sherlock/.krew exists and is owned by sherlock
KREW_OWNER=$(run_in_container stat -c '%U' /home/sherlock/.krew)
check_assert ".krew owned by sherlock" "$KREW_OWNER" "sherlock"

# Verify no SUID binaries in common paths
TEST_NUMBER=$((TEST_NUMBER + 1))
SUID_BINS=$(run_in_container find /usr/bin /usr/sbin /usr/local/bin -perm -4000 2>/dev/null || true)
if [ -z "$SUID_BINS" ]; then
    if [ "$CI_MODE" = true ]; then
        echo "ok $TEST_NUMBER - no SUID binaries"
    else
        printf "  %-25s" "no SUID binaries"; echo -e "${GREEN}PASS${NC}"
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
else
    if [ "$CI_MODE" = true ]; then
        echo "not ok $TEST_NUMBER - no SUID binaries"
        echo "#   found SUID binaries: $SUID_BINS"
    else
        printf "  %-25s" "no SUID binaries"; echo -e "${RED}FAIL${NC}"
        echo -e "    ${RED}→ found SUID binaries: $SUID_BINS${NC}"
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ─────────────────────────────────────────────
# Image Metadata (OCI Labels)
# ─────────────────────────────────────────────

section "Image Metadata"

OCI_TITLE=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.title" }}' "$IMAGE_NAME")
OCI_LICENSE=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.licenses" }}' "$IMAGE_NAME")
OCI_SOURCE=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.source" }}' "$IMAGE_NAME")

TEST_NUMBER=$((TEST_NUMBER + 1))
if [ -n "$OCI_TITLE" ]; then
    if [ "$CI_MODE" = true ]; then
        echo "ok $TEST_NUMBER - OCI label: title"
    else
        printf "  %-25s" "OCI label: title"; echo -e "${GREEN}PASS${NC}"
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
else
    if [ "$CI_MODE" = true ]; then
        echo "not ok $TEST_NUMBER - OCI label: title"
    else
        printf "  %-25s" "OCI label: title"; echo -e "${RED}FAIL${NC}"
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

TEST_NUMBER=$((TEST_NUMBER + 1))
if [ -n "$OCI_LICENSE" ]; then
    if [ "$CI_MODE" = true ]; then
        echo "ok $TEST_NUMBER - OCI label: licenses"
    else
        printf "  %-25s" "OCI label: licenses"; echo -e "${GREEN}PASS${NC}"
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
else
    if [ "$CI_MODE" = true ]; then
        echo "not ok $TEST_NUMBER - OCI label: licenses"
    else
        printf "  %-25s" "OCI label: licenses"; echo -e "${RED}FAIL${NC}"
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

TEST_NUMBER=$((TEST_NUMBER + 1))
if [ -n "$OCI_SOURCE" ]; then
    if [ "$CI_MODE" = true ]; then
        echo "ok $TEST_NUMBER - OCI label: source"
    else
        printf "  %-25s" "OCI label: source"; echo -e "${GREEN}PASS${NC}"
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
else
    if [ "$CI_MODE" = true ]; then
        echo "not ok $TEST_NUMBER - OCI label: source"
    else
        printf "  %-25s" "OCI label: source"; echo -e "${RED}FAIL${NC}"
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ─────────────────────────────────────────────
# HEALTHCHECK Validation
# ─────────────────────────────────────────────

section "HEALTHCHECK Validation"

TEST_NUMBER=$((TEST_NUMBER + 1))
HEALTHCHECK=$(docker inspect --format '{{ .Config.Healthcheck }}' "$IMAGE_NAME")
if [ -n "$HEALTHCHECK" ] && [ "$HEALTHCHECK" != "<nil>" ]; then
    if [ "$CI_MODE" = true ]; then
        echo "ok $TEST_NUMBER - HEALTHCHECK configured"
    else
        printf "  %-25s" "HEALTHCHECK configured"; echo -e "${GREEN}PASS${NC}"
    fi
    PASS_COUNT=$((PASS_COUNT + 1))
else
    if [ "$CI_MODE" = true ]; then
        echo "not ok $TEST_NUMBER - HEALTHCHECK configured"
    else
        printf "  %-25s" "HEALTHCHECK configured"; echo -e "${RED}FAIL${NC}"
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ─────────────────────────────────────────────
# Kubernetes CLI Tools
# ─────────────────────────────────────────────

section "Kubernetes CLI Tools"

check_tool "kubectl"          kubectl version --client
check_tool "helm"             helm version --short
check_tool "k9s"              k9s version --short
check_tool "kubectx"          kubectx --help
check_tool "kubens"           kubens --help
check_tool "stern"            stern --version
check_tool "kustomize"        kustomize version
check_tool "krew"             kubectl krew version
check_tool "kubectl-neat"     kubectl neat --help

# ─────────────────────────────────────────────
# Security & Validation Tools
# ─────────────────────────────────────────────

section "Security & Validation Tools"

check_tool "trivy"            trivy --version
check_tool "kubeconform"      kubeconform -v

# ─────────────────────────────────────────────
# Container & Development Tools
# ─────────────────────────────────────────────

section "Container & Development Tools"

check_tool "dive"             dive --version
check_tool "telepresence"     telepresence version

# ─────────────────────────────────────────────
# Data Processing Tools
# ─────────────────────────────────────────────

section "Data Processing Tools"

check_tool "jq"               jq --version
check_tool "yq"               yq --version

# ─────────────────────────────────────────────
# System & Network Tools
# ─────────────────────────────────────────────

section "System & Network Tools"

check_tool "curl"             curl --version
check_tool "wget"             wget --version
check_tool "git"              git --version
check_tool "python3"          python3 --version
check_tool "fzf"              fzf --version
check_tool "socat"            socat -V
check_tool "tcpdump"          tcpdump --version
check_tool "dig"              dig -v
check_tool "ping"             ping -c 1 -W 2 127.0.0.1
check_tool "netcat"           nc -h
check_tool "vim"              vim --version

# ─────────────────────────────────────────────
# Test Summary
# ─────────────────────────────────────────────

TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))

if [ "$CI_MODE" = true ]; then
    echo "1..$TOTAL"
    echo "# Tests: $TOTAL"
    echo "# Pass:  $PASS_COUNT"
    echo "# Fail:  $FAIL_COUNT"
    if [ "$SKIP_COUNT" -gt 0 ]; then
        echo "# Skip:  $SKIP_COUNT"
    fi
else
    echo ""
    echo "=============================="
    echo -e "${BOLD}Test Summary${NC}"
    echo "=============================="
    echo -e "  Total:   $TOTAL"
    echo -e "  ${GREEN}Passed:  $PASS_COUNT${NC}"
    echo -e "  ${RED}Failed:  $FAIL_COUNT${NC}"
    if [ "$SKIP_COUNT" -gt 0 ]; then
        echo -e "  ${YELLOW}Skipped: $SKIP_COUNT${NC}"
    fi
    echo "=============================="
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "${RED}${BOLD}FAILED${NC} - $FAIL_COUNT tool(s) not working correctly."
    exit 1
else
    echo -e "${GREEN}${BOLD}ALL TESTS PASSED${NC}"
    exit 0
fi
