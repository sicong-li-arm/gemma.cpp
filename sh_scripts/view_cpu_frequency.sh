CPU_SYSFS="/sys/devices/system/cpu"
PIDS=$(ls -d ${CPU_SYSFS}/cpu[0-9]* | grep -o '[0-9]*')
 
echo -e "Core | CurFreq (kHz) | Governor     | Available Frequencies (kHz)           | Available Governors"
echo "-----+---------------+--------------+---------------------------------------+--------------------------"
 
for cpu in $PIDS; do
  base="${CPU_SYSFS}/cpu${cpu}/cpufreq"
  if [ -d "$base" ]; then
    curf=$(cat "${base}/scaling_cur_freq" 2>/dev/null)
    gov=$(cat "${base}/scaling_governor" 2>/dev/null)
    availf=$(cat "${base}/scaling_available_frequencies" 2>/dev/null | tr ' ' ',')
    availg=$(cat "${base}/scaling_available_governors" 2>/dev/null | tr ' ' ',')
    printf "%4s | %12s | %12s | %37s | %s\n" "$cpu" "${curf:-N/A}" "${gov:-N/A}" "${availf:-N/A}" "${availg:-N/A}"
  else
    printf "%4s | %12s | %12s | %37s | %s\n" "$cpu" "N/A" "N/A" "N/A" "N/A"
  fi
done
