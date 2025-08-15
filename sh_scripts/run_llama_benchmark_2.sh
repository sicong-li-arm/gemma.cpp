#!/bin/bash

# CONFIG
DEVICE_DIR="/tmp/llm_game/llama"
LOCAL_RESULTS_DIR="./benchmark_results_host"

# Ensure host-side results folder exists
mkdir -p "$LOCAL_RESULTS_DIR"

# Fetch each file after it's created
echo "Starting benchmark loop and streaming results to host..."

# Define a tiny runner script to execute one benchmark at a time and pull it
adb shell "mkdir -p $DEVICE_DIR/benchmark_results"

adb shell "su -c 'cmd power set-fixed-performance-mode-enabled true'"

THREADS=(1 2 4 6 8)
BATCH_SIZES=(1 8 32)
#THREADS=(8)
#BATCH_SIZES=(32)
DIRS=("no_kleidi" "kleidi")

for DIR in "${DIRS[@]}"; do
  for t in "${THREADS[@]}"; do
    for b in "${BATCH_SIZES[@]}"; do
      FILENAME="${DIR}_t${t}_b${b}.json"
      echo "▶️ Running: $DIR t=$t b=$b"

      #adb shell "cd $DEVICE_DIR && DIR=$DIR T=$t B=$b su -c ' \
      #  cd \$DIR
      #  source ../export_ld_path.sh
      #  ../set_top_cpu_frequency.sh
      #  sleep 1
      #  ../set_top_cpu_frequency.sh
      #  ./llama-bench -m ../gemma-3-1b-it-q4_0.gguf \
      #    -C 0xF0 --cpu-strict 1 -t \$T -b \$B -ub \$B -o json \
      #    > $DEVICE_DIR/benchmark_results/$FILENAME
      #  ../set_default_cpu_frequency.sh
      #  sleep 1
      #  ../set_default_cpu_frequency.sh
      #  sleep 30
      #'"
      adb shell "cd $DEVICE_DIR/$DIR && DIR=$DIR T=$t B=$b su -c ' \
        source ../export_ld_path.sh
        ../set_top_cpu_frequency.sh
        sleep 1
        ../set_top_cpu_frequency.sh
        ./llama-bench -m ../gemma-3-1b-it-q4_0.gguf \
          -C 0xF0 --cpu-strict 1 -t \$T -b \$B -ub \$B -o json \
          > $DEVICE_DIR/benchmark_results/$FILENAME
        ../set_default_cpu_frequency.sh
        sleep 1
        ../set_default_cpu_frequency.sh
        sleep 30
      '"

      echo "⬇️ Pulling result: $FILENAME"
      adb pull "$DEVICE_DIR/benchmark_results/$FILENAME" "$LOCAL_RESULTS_DIR/$FILENAME"
    done
  done
done
adb shell "su -c 'cmd power set-fixed-performance-mode-enabled false'"

echo "✅ All benchmarks done. Results saved to: $LOCAL_RESULTS_DIR"
