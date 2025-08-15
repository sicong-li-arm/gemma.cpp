#!/bin/bash

# File: run_llama_benchmark.sh

DEVICE_DIR="/tmp/llm_game/llama"
LOCAL_RESULTS_DIR="./benchmark_results_host"

echo "📦 Creating benchmark script directly on the device..."

adb root

adb shell "mkdir -p $DEVICE_DIR && cat > $DEVICE_DIR/run_benchmark_loop.sh" <<'EOF'
# Requires root
su
#THREADS=(1 2 4 6 8)
#BATCH_SIZES=(1 8 32)
THREADS=(4)
BATCH_SIZES=(32)

##
# run_benchmark
# -------------
# Arguments:
#   $1 - Directory name (e.g., "no_kleidi" or "kleidi")
##
run_benchmark() {
  DIR=$1
  cd "$DIR" || exit 1
  source ../export_ld_path.sh

  for t in "${THREADS[@]}"; do
    for b in "${BATCH_SIZES[@]}"; do
      echo "Running $DIR: threads=$t, batch_size=$b"
      ../set_top_cpu_frequency.sh
      ../llama-bench -m ../gemma-3-1b-it-q4_0.gguf \
        -C 0xF0 --cpu-strict 1 -t "$t" -b "$b" -ub 1 -o json \
        > "../benchmark_results/${DIR}_t${t}_b${b}.json"
      ../set_default_cpu_frequency.sh
      sleep 30
    done
  done

  cd - || exit 1
}

mkdir -p ./benchmark_results
run_benchmark "no_kleidi"
run_benchmark "kleidi"
EOF

# Make the script executable
adb shell "chmod +x $DEVICE_DIR/run_benchmark_loop.sh"

echo "🚀 Running benchmark script on device..."
adb shell "cd $DEVICE_DIR && ./run_benchmark_loop.sh"

echo "📥 Pulling benchmark results from device..."
mkdir -p "$LOCAL_RESULTS_DIR"
adb pull "$DEVICE_DIR/benchmark_results" "$LOCAL_RESULTS_DIR"

echo "✅ Done. Results saved to: $LOCAL_RESULTS_DIR/benchmark_results"
