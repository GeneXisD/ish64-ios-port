#!/usr/bin/env bash
# auto_fix_ish_wrappers.sh
# Generates 6-arg wrapper functions for all syscalls to avoid cast-function-type warnings

KERNEL_DIR="./kernel"
CALLS_FILE="$KERNEL_DIR/calls.c"
WRAPPER_FILE="$KERNEL_DIR/syscall_wrappers.c"

echo "// AUTO-GENERATED WRAPPERS - DO NOT EDIT MANUALLY" > "$WRAPPER_FILE"
echo "#include \"calls.h\"" >> "$WRAPPER_FILE"
echo "" >> "$WRAPPER_FILE"

# For each syscall function declaration in kernel
grep -E "int_t sys_[a-z0-9_]+\(" "$KERNEL_DIR"/*.c | while read -r line; do
    # Extract syscall name
    SYSCALL=$(echo "$line" | sed -E 's/.*(sys_[a-z0-9_]+)\(.*/\1/')
    # Extract arguments
    ARGS=$(echo "$line" | sed -E 's/.*\((.*)\).*/\1/')
    # Count arguments
    NUM_ARGS=$(echo "$ARGS" | awk -F',' '{if($1=="") print 0; else print NF}')

    # Generate wrapper function
    echo "static int syscall_${SYSCALL}_wrapper(unsigned int a, unsigned int b, unsigned int c," >> "$WRAPPER_FILE"
    echo "                                       unsigned int d, unsigned int e, unsigned int f) {" >> "$WRAPPER_FILE"

    # Build argument list for original syscall
    CALL_ARGS=""
    if [[ "$NUM_ARGS" -gt 0 ]]; then
        # Use first N letters for args
        LETTERS=(a b c d e f)
        for i in $(seq 0 $((NUM_ARGS-1))); do
            if [ -z "$CALL_ARGS" ]; then
                CALL_ARGS="${LETTERS[$i]}"
            else
                CALL_ARGS="${CALL_ARGS}, ${LETTERS[$i]}"
            fi
        done
    fi

    echo "    return $SYSCALL($CALL_ARGS);"
    echo "}" >> "$WRAPPER_FILE"
    echo "" >> "$WRAPPER_FILE"
done

echo "Wrappers generated in $WRAPPER_FILE."
echo "Next: include this file in calls.c and replace syscall_table assignments with wrappers."
