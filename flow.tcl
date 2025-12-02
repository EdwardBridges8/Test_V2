#=========================================================
# Formality Post-DC Verification Script for mydsm Design
#=========================================================

# Set workspace path
set WORKSPACE "/SM05/home/phd2024/phd202411094979/project/cpicp25"
set FORMALITY_PATH "$WORKSPACE/digtal/formality"
set SYN_PATH "$WORKSPACE/digtal/syn"
set SRC_PATH "$WORKSPACE/digtal/front/src"
set PDK_PATH "$WORKSPACE/pdk"
set STD_CELL_PATH "$PDK_PATH/STDCELL/SCC28NHKCP_HDC30P140_RVT_V0p2"

# Design and report settings
set DESIGN_NAME "mydsm"
set REPORTS_DIR "$FORMALITY_PATH/reports"
file mkdir ${REPORTS_DIR}

# Input file settings
set RESULTS_DIR "$SYN_PATH/outputs"
set DCRM_SVF_OUTPUT_FILE "${DESIGN_NAME}_syn.svf"
set DCRM_FINAL_VERILOG_OUTPUT_FILE "${DESIGN_NAME}_syn.v"

# Report file names
set FMRM_UNMATCHED_POINTS_REPORT "unmatched_points.rpt"
set FMRM_FAILING_SESSION_NAME "failing_session"
set FMRM_FAILING_POINTS_REPORT "failing_points.rpt"
set FMRM_ABORTED_POINTS_REPORT "aborted_points.rpt"
set FMRM_ANALYZE_POINTS_REPORT "analyze_points.rpt"

puts "=============================================="
puts "    Formality Post-DC Verification Flow       "
puts "=============================================="
puts "Workspace: $WORKSPACE"
puts "Design   : $DESIGN_NAME"
puts "Reports  : $REPORTS_DIR"
puts "=============================================="

#=========================================================
# Library Setup
#=========================================================
puts "Setting up libraries..."

# Set library paths - using same libraries as synthesis
set LIB_SS_ECSM "$STD_CELL_PATH/liberty/0.9v/scc28nhkcp_hdc30p140_rvt_ss_v0p81_125c_ecsm.db"
set LIB_TT_ECSM "$STD_CELL_PATH/liberty/0.9v/scc28nhkcp_hdc30p140_rvt_tt_v0p9_25c_ecsm.db"
set LIB_FF_ECSM "$STD_CELL_PATH/liberty/0.9v/scc28nhkcp_hdc30p140_rvt_ff_v0p99_-40c_ecsm.db"

# Set additional link library files
set ADDITIONAL_LINK_LIB_FILES "$LIB_SS_ECSM $LIB_TT_ECSM $LIB_FF_ECSM"

# RTL source files - same as used in synthesis
set RTL_SOURCE_FILES "$SRC_PATH/mydsm.v $SRC_PATH/ifa.v $SRC_PATH/mash111.v"

#=========================================================
# Formality Settings
#=========================================================
puts "Configuring Formality settings..."

# Setup for handling undriven signals in the design
set verification_set_undriven_signals x 

# To treat simulation and synthesis mismatch messages as warning
set_app_var hdlin_error_on_mismatch_message false

# Set verification parameters
set_app_var verification_verify_directly_undriven_output true
set_app_var hdlin_translate_off_skip_text true
set_app_var hdlin_enable_presto_for_verilog true

#=========================================================
# Read SVF File
#=========================================================
puts "Reading SVF file..."

# Read in the SVF file for advanced verification
if {[file exists ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}]} {
    set_svf ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}
    puts "SVF file loaded: ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}"
} else {
    puts "Warning: SVF file not found at ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}"
}

#=========================================================
# Read Technology Libraries
#=========================================================
puts "Reading technology libraries..."

# Read in the technology libraries
read_db -technology_library ${ADDITIONAL_LINK_LIB_FILES}

#=========================================================
# Read Reference Design (RTL)
#=========================================================
puts "Reading reference design (RTL)..."

# Read in the Reference design (RTL sources)
read_verilog -r ${RTL_SOURCE_FILES} -work_library WORK
set_top r:/WORK/${DESIGN_NAME}

#=========================================================
# Read Implementation Design (Netlist)
#=========================================================
puts "Reading implementation design (netlist)..."

# Read in the Implementation design (synthesized netlist)
read_verilog -i ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}
set_top i:/WORK/${DESIGN_NAME}

#=========================================================
# Setup and Match
#=========================================================
puts "Setting up and matching compare points..."

# Set the top-level design for both reference and implementation
# set_user_match -type port -ref r:/WORK/${DESIGN_NAME} -impl i:/WORK/${DESIGN_NAME}

# Match compare points and report unmatched points
match

# Generate match reports
report_unmatched_points > ${REPORTS_DIR}/${FMRM_UNMATCHED_POINTS_REPORT}
report_matched_points > ${REPORTS_DIR}/matched_points.rpt

#=========================================================
# Verification
#=========================================================
puts "Starting verification..."

# Verify and report results
if { ![verify] } {
    puts "ERROR: Verification FAILED!"
    save_session -replace ${REPORTS_DIR}/${FMRM_FAILING_SESSION_NAME}
    report_failing_points > ${REPORTS_DIR}/${FMRM_FAILING_POINTS_REPORT}
    report_aborted > ${REPORTS_DIR}/${FMRM_ABORTED_POINTS_REPORT}
    analyze_points -all > ${REPORTS_DIR}/${FMRM_ANALYZE_POINTS_REPORT}
    puts "Failed session saved to: ${REPORTS_DIR}/${FMRM_FAILING_SESSION_NAME}"
    puts "Please check the following reports:"
    puts "  - ${REPORTS_DIR}/${FMRM_FAILING_POINTS_REPORT}"
    puts "  - ${REPORTS_DIR}/${FMRM_ABORTED_POINTS_REPORT}"
    puts "  - ${REPORTS_DIR}/${FMRM_ANALYZE_POINTS_REPORT}"
} else {
    puts "SUCCESS: Verification PASSED!"
    puts "All compare points have been successfully verified."
}

#=========================================================
# Additional Reports
#=========================================================
puts "Generating additional reports..."

# Generate comprehensive verification reports
report_guidance > ${REPORTS_DIR}/guidance.rpt
report_status > ${REPORTS_DIR}/status.rpt

# Save successful session for future reference
save_session -replace ${REPORTS_DIR}/verification_session

puts "=============================================="
puts "    Formality Verification Completed          "
puts "=============================================="
puts "Reports saved to: $REPORTS_DIR"
puts "=============================================="

exit
