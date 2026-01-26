#!/bin/bash
set -euo pipefail

wait_for_trigger_terminal() {
    local trigger_ref="$1"
    local timeout="${2:-30}"
    local interval="${3:-1}"

    local elapsed=0
    local exec_json
    local exec_id
    local status
    local trigger_trn=""

    if [[ "$trigger_ref" == trn:* ]]; then
        trigger_trn="$trigger_ref"
    else
        trigger_trn=$($CLI -o json tr get "$trigger_ref" 2>/dev/null | jq -r '.trn // empty')
    fi

    while [ $elapsed -lt $timeout ]; do
        if [ -n "$trigger_trn" ]; then
            exec_json=$($CLI -o json tr exec list --trigger "$trigger_trn" --limit 1 2>/dev/null || echo "[]")
        else
            exec_json=$($CLI -o json tr exec list --trigger "$trigger_ref" --limit 1 2>/dev/null || echo "[]")
        fi

        if [ -n "$trigger_trn" ]; then
            exec_id=$(echo "$exec_json" | jq -r --arg trn "$trigger_trn" '.[] | select(.triggerTrn == $trn) | .id' | head -n 1)
            status=$(echo "$exec_json" | jq -r --arg trn "$trigger_trn" '.[] | select(.triggerTrn == $trn) | .status' | head -n 1)
        else
            exec_id=$(echo "$exec_json" | jq -r '.[0].id // empty')
            status=$(echo "$exec_json" | jq -r '.[0].status // empty')
        fi

        if [ -n "$exec_id" ]; then
            case "$status" in
                succeeded|failed|timeout|cancelled)
                    echo "$exec_json"
                    return 0
                    ;;
            esac
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    return 1
}
