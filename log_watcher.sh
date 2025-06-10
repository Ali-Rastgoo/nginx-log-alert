#!/bin/bash

LOG_FILE="$(pwd)/logs/access.log"
ALERT_LOG="$(pwd)/alert.log"
INTERVAL=30
THRESHOLD=10
FAIL_COUNT=0

echo "🚀 Starting NGINX Log Watcher..."
echo "Monitoring: $LOG_FILE"
echo "Alerts will be logged to: $ALERT_LOG"
echo "---------------------------------------------------"

while true; do
  echo "[INFO] Checking logs..." >> $ALERT_LOG
  echo "🔍 Checking last 100 log entries..."

  TOTAL=$(tail -n 100 "$LOG_FILE" | wc -l)
  ERRORS=$(tail -n 100 "$LOG_FILE" | awk '$9 ~ /^5/ {count++} END {print count+0}')

  if [ "$TOTAL" -eq 0 ]; then
    echo "[WARN] No log entries found." | tee -a $ALERT_LOG
  else
    PERCENT=$(echo "scale=2; $ERRORS*100/$TOTAL" | bc)

    echo "📊 Total Requests: $TOTAL | 5xx Errors: $ERRORS | Error Rate: $PERCENT%"

    if (( $(echo "$PERCENT > $THRESHOLD" | bc -l) )); then
      echo "[ALERT] High 5xx rate: $PERCENT% at $(date)" | tee -a $ALERT_LOG
      ((FAIL_COUNT++))
      echo "⚠️ Consecutive failures: $FAIL_COUNT"
    else
      echo "[OK] 5xx rate within acceptable range." | tee -a $ALERT_LOG
      FAIL_COUNT=0
    fi
  fi

  if [ "$FAIL_COUNT" -ge 3 ]; then
    TS=$(date +%Y%m%d-%H%M%S)
    CRITICAL_FILE="CRITICAL-$TS.txt"
    echo "[CRITICAL] Generating report: $CRITICAL_FILE" | tee -a $ALERT_LOG

    {
      echo "⚠️ CRITICAL REPORT @ $TS"
      echo "=== Running Containers ==="
      docker ps
      echo -e "\n=== Last 20 error logs ==="
      grep " 5[0-9][0-9] " "$LOG_FILE" | tail -n 20
    } > "$CRITICAL_FILE"

    echo "🛑 CRITICAL report saved: $CRITICAL_FILE"
    FAIL_COUNT=0
  fi

  echo "⏳ Sleeping for $INTERVAL seconds..."
  echo "---------------------------------------------------"
  sleep $INTERVAL
done
