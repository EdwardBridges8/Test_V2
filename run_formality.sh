#!/bin/bash

#=========================================================
# Formality Post-DC Verification Run Script for mydsm
#=========================================================

echo "=============================================="
echo "    Starting Formality Post-DC Verification   "
echo "=============================================="

# Set the workspace directory
WORKSPACE="/SM05/home/phd2024/phd202411094979/project/cpicp25"
FORMALITY_DIR="$WORKSPACE/digtal/formality"

# Change to formality directory
cd $FORMALITY_DIR/runspace


# Run Formality with the flow script
echo "Running Formality with flow.tcl..."
echo "Command: fm_shell -overwrite -f scripts/flow.tcl | tee formality.log"

fm_shell -overwrite -f ../scripts/flow.tcl | tee formality.log

echo "=============================================="
echo "    Formality Verification Completed          "
echo "=============================================="


# Check if verification passed
if grep -q "SUCCESS: Verification PASSED!" formality.log; then
    echo "✓ VERIFICATION SUCCESSFUL - All compare points matched!"
    exit 0
elif grep -q "ERROR: Verification FAILED!" formality.log; then
    echo "✗ VERIFICATION FAILED - Please check the reports for details"
    exit 1
else
    echo "? VERIFICATION STATUS UNCLEAR - Please check the log file"
    exit 2
fi