#!/bin/bash
# Script to compare field access performance between master and current branch
#
# Usage: ./perf/compare_branches.sh

set -e

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
RESULTS_DIR="perf/results"

mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "Branch Performance Comparison"
echo "=========================================="
echo ""
echo "Current branch: $CURRENT_BRANCH"
echo "Baseline: master"
echo ""

# Run benchmark on current branch
echo "Running benchmark on current branch..."
ruby perf/benchmark_field_cache.rb > "$RESULTS_DIR/current_branch.txt" 2>&1

# Stash any uncommitted changes
STASHED=0
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Stashing uncommitted changes..."
    git stash push -m "Temporary stash for benchmark comparison"
    STASHED=1
fi

# Switch to master and run benchmark
echo "Switching to master branch..."
git checkout master

echo "Running benchmark on master..."
ruby perf/benchmark_field_cache.rb > "$RESULTS_DIR/master.txt" 2>&1

# Switch back to original branch
echo "Switching back to $CURRENT_BRANCH..."
git checkout "$CURRENT_BRANCH"

# Restore stashed changes if any
if [ $STASHED -eq 1 ]; then
    echo "Restoring stashed changes..."
    git stash pop
fi

echo ""
echo "=========================================="
echo "Results Summary"
echo "=========================================="
echo ""
echo "Master results:"
grep "i/s" "$RESULTS_DIR/master.txt" | head -7
echo ""
echo "Current branch results:"
grep "i/s" "$RESULTS_DIR/current_branch.txt" | head -7
echo ""
echo "Full results saved to:"
echo "  - $RESULTS_DIR/master.txt"
echo "  - $RESULTS_DIR/current_branch.txt"
echo ""
echo "Compare results with: diff -y $RESULTS_DIR/master.txt $RESULTS_DIR/current_branch.txt"
echo "=========================================="
