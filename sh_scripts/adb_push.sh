LLAMA_BUILD="/home/sicli01/Projects/llama.cpp/build-android-no-kleidi"
GEMMA_MODEL="/home/sicli01/Projects/gemma3_gguf/gemma-3-1b-it-q4_0.gguf"
DEST="/tmp/llm_game/llama"

adb shell "mkdir -p $DEST"
adb shell 'echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:." > ${DEST}/export_ld_path.sh'
adb push ${GEMMA_MODEL} 					$DEST
adb push ${LLAMA_BUILD}/bin/libllama.so 			$DEST
adb push ${LLAMA_BUILD}/bin/libggml.so 				$DEST
adb push ${LLAMA_BUILD}/bin/libggml-cpu.so 			$DEST
adb push ${LLAMA_BUILD}/bin/libggml-base.so 			$DEST
adb push ${LLAMA_BUILD}/bin/llama-cli 				$DEST
adb push ${LLAMA_BUILD}/bin/llama-bench 			$DEST

adb shell "cd $DEST && chmod +x *"
