#!/bin/bash
# Running CONFIG
#DEVICE_DIR="/tmp/llm_game/llama"
DEVICE_DIR="/data/local/tmp/sicli01/llm_game/llama"
LOCAL_RESULTS_DIR="./benchmark_results_host_default_freq_order1_s24ultra"

# Push File CONFIG
NO_KLEIDI_DIR="/home/sicli01/Projects/llama.cpp/build-android-no-kleidi"
KLEIDI_DIR="/home/sicli01/Projects/llama.cpp/build-android-kleidi"
MODEL_FILE="gemma-3-1b-it-q4_0.gguf"
MODEL_DIR="/home/sicli01/Projects/gemma3_gguf"
MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"

# Setting up remote device dir TODO: refactor out of the script
# DEVICE_DIR
#	- export_ld_path.sh
#  	- MODEL_FILE
#  	- kleidi/
#  	     - *.so
#  	     - llama-bench
#  	- no_kleidi/
#  	     - *.so
#  	     - llama-bench

adb shell "su -c 'mkdir -p $DEVICE_DIR && chmod 777 $DEVICE_DIR && cat > $DEVICE_DIR/export_ld_path.sh'" << 'EOF'
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
EOF

function push_llama() {
	local src=$1
	local dst=$2
	adb shell "su -c 'mkdir -p $dst && chmod 777 $dst'"
	cd ${src}
	adb push ./bin/libllama.so $dst
	adb push ./bin/libggml.so $dst
	adb push ./bin/libggml-cpu.so $dst
	adb push ./bin/libggml-base.so $dst
	adb push ./bin/llama-bench $dst
	#adb push ./bin/llama-cli $dst
	cd -
}
#push_llama $NO_KLEIDI_DIR $DEVICE_DIR/no_kleidi
#push_llama $KLEIDI_DIR $DEVICE_DIR/kleidi

#adb push $MODEL_PATH $DEVICE_DIR


# Ensure host-side results folder exists
mkdir -p "$LOCAL_RESULTS_DIR"

# Fetch each file after it's created
echo "Starting benchmark loop and streaming results to host..."

# Define a tiny runner script to execute one benchmark at a time and pull it
adb shell "su -c 'mkdir -p $DEVICE_DIR/benchmark_results'"

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

      adb shell "cd $DEVICE_DIR/$DIR && DIR=$DIR T=$t B=$b su -c ' \
        source ../export_ld_path.sh
        ./llama-bench -m ../$MODEL_FILE \
          -t \$T -b \$B -ub \$B -o json \
          > $DEVICE_DIR/benchmark_results/$FILENAME
        sleep 30
      '"

      echo "⬇️ Pulling result: $FILENAME"
      adb pull "$DEVICE_DIR/benchmark_results/$FILENAME" "$LOCAL_RESULTS_DIR/$FILENAME"
    done
  done
done

echo "✅ All benchmarks done. Results saved to: $LOCAL_RESULTS_DIR"
