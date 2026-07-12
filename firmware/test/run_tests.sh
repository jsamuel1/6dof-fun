#!/usr/bin/env bash
# Build and run the host-side firmware unit tests (no hardware, no Arduino).
# Exits nonzero on compile error or any test failure.
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p build

clang++ -std=c++17 -Wall -Wextra -O2 \
  -I../arm_controller \
  -o build/arm_tests \
  test_main.cpp ../arm_controller/trajectory.cpp

./build/arm_tests
