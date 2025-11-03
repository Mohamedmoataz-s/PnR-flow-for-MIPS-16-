##############################################
########### 1. DESIGN SETUP ##################
##############################################

set design mips_16

sh rm -rf $design

set sc_dir "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12"

set_app_var search_path "/home/standard_cell_libraries/NangateOpenCellLibrary_PDKv1_3_v2010_12/lib/Front_End/Liberty/NLDM \
			 /home/mohamed/Desktop/johnson/rtl"

set_app_var link_library "* NangateOpenCellLibrary_ss0p95vn40c.db"
set_app_var target_library "NangateOpenCellLibrary_ss0p95vn40c.db"

## Create Milkyway Library
##########################
create_mw_lib   ./${design} \
                -technology $sc_dir/tech/techfile/milkyway/FreePDK45_10m.tf \
		-mw_reference_library $sc_dir/lib/Back_End/mdb \
		-hier_separator {/} \
		-bus_naming_style {[%d]} \
		-open

## Set TLU+ Files for RC Extraction
###################################
set tlupmax "$sc_dir/tech/rcxt/FreePDK45_10m_Cmax.tlup"
set tlupmin "$sc_dir/tech/rcxt/FreePDK45_10m_Cmin.tlup"
set tech2itf "$sc_dir/tech/rcxt/FreePDK45_10m.map"

set_tlu_plus_files -max_tluplus $tlupmax \
                   -min_tluplus $tlupmin \
     		   -tech2itf_map $tech2itf

## Import Design
################
import_designs  ../syn/output/${design}.v \
                -format verilog \
		-top ${design} \
		-cel ${design}

## Apply Constraints
###################
source  ../syn/cons/cons.tcl
set_propagated_clock [get_clocks clk]

save_mw_cel -as ${design}_1_imported

##############################################
########### 2. T-SHAPED FLOORPLAN ############
##############################################

## Create Starting Floorplan (Rectangular base)
################################################
# Increased core utilization to accommodate T-shape constraints
create_floorplan -core_utilization 0.35 \
	-start_first_row -flip_first_row \
	-left_io2core 12.4 -bottom_io2core 12.4 -right_io2core 12.4 -top_io2core 12.4

## Get floorplan dimensions for T-shape calculations
####################################################
set fp_bbox [get_attribute [get_core_area] bbox]
set core_llx [lindex [lindex $fp_bbox 0] 0]
set core_lly [lindex [lindex $fp_bbox 0] 1] 
set core_urx [lindex [lindex $fp_bbox 1] 0]
set core_ury [lindex [lindex $fp_bbox 1] 1]

set core_width [expr $core_urx - $core_llx]
set core_height [expr $core_ury - $core_lly]

## Calculate T-shape dimensions
###############################
# Adjust these ratios based on your desired T-shape proportions
set t_top_width_ratio 1.0      ;# Top bar uses full width
set t_stem_width_ratio 0.4     ;# Vertical stem width as ratio of total width  
set t_top_height_ratio 0.4     ;# Top bar height as ratio of total height

set t_top_width [expr $core_width * $t_top_width_ratio]
set t_stem_width [expr $core_width * $t_stem_width_ratio]
set t_top_height [expr $core_height * $t_top_height_ratio]

## Calculate blockage coordinates for T-shape
##############################################
set top_bar_start_y [expr $core_ury - $t_top_height]
set stem_center_x [expr $core_llx + $core_width/2.0]
set stem_left_x [expr $stem_center_x - $t_stem_width/2.0] 
set stem_right_x [expr $stem_center_x + $t_stem_width/2.0]

## Create placement blockages to form T-shape
##############################################
puts "Creating T-shaped floorplan with placement blockages..."

# Block left bottom area (outside T-stem)
create_placement_blockage -name "T_block_left" -type hard \
    -bbox [list $core_llx $core_lly $stem_left_x $top_bar_start_y]

# Block right bottom area (outside T-stem)
create_placement_blockage -name "T_block_right" -type hard \
    -bbox [list $stem_right_x $core_lly $core_urx $top_bar_start_y]

## Create routing blockages for cleaner T-shape
################################################
create_routing_blockage -name "T_route_block_left" \
    -bbox [list $core_llx $core_lly $stem_left_x $top_bar_start_y] \
    -layers {metal1 metal2 metal3 metal4 metal5 metal6}

create_routing_blockage -name "T_route_block_right" \
    -bbox [list $stem_right_x $core_lly $core_urx $top_bar_start_y] \
    -layers {metal1 metal2 metal3 metal4 metal5 metal6}

## CONSTRAINTS
##############
report_ignored_layers
remove_ignored_layers -all
set_ignored_layers -max_routing_layer metal6

## Initial Virtual Flat Placement for T-shape
##############################################
create_fp_placement -timing -no_hierarchy_gravity -congestion

## Module-specific placement in T-regions (Optional)
####################################################
# Uncomment and modify based on your specific modules

# Place ALU in the top bar region
# create_bounds -name "top_bar_alu" \
#     -coordinate [list $core_llx $top_bar_start_y $core_urx $core_ury] \
#     [get_cells "alu_unit/*"]

# Place register file in the stem region  
# create_bounds -name "stem_regfile" \
#     -coordinate [list $stem_left_x $core_lly $stem_right_x $top_bar_start_y] \
#     [get_cells "reg_file/*"]

# Place data memory in remaining top area
# create_bounds -name "top_bar_datamem" \
#     -coordinate [list [expr $core_llx + $core_width*0.6] $top_bar_start_y $core_urx $core_ury] \
#     [get_cells "datamem/*"]

## Print T-shape information for verification
#############################################
puts "=== T-SHAPE FLOORPLAN CREATED ==="
puts "Core area: [format "%.2f" $core_width] x [format "%.2f" $core_height]"
puts "T-top bar: [format "%.2f" $t_top_width] x [format "%.2f" $t_top_height]"
puts "T-stem: [format "%.2f" $t_stem_width] x [format "%.2f" [expr $core_height - $t_top_height]]"
puts "Top bar region: ([format "%.1f" $core_llx], [format "%.1f" $top_bar_start_y]) to ([format "%.1f" $core_urx], [format "%.1f" $core_ury])"
puts "Stem region: ([format "%.1f" $stem_left_x], [format "%.1f" $core_lly]) to ([format "%.1f" $stem_right_x], [format "%.1f" $top_bar_start_y])"

## ASSESSMENT
#############
# Analyze Congestion
route_fp_proto -congestion_map_only -effort medium    
# View Congestion map: In GUI, Route > Global Route Congestion Map

# Analyze Timing
extract_rc  # Improves accuracy of timing after updated GR

report_timing -nosplit                                    # Worst Setup violation
report_timing -nosplit -delay_type min                    # Worst Hold violation
report_constraint -all_violators -nosplit -max_delay     # All Setup violations
report_constraint -all_violators -nosplit -min_delay     # All Hold violations

## FIXES (if needed based on assessment results)
################################################
# If congestion or timing issues occur, try these fixes:

# 1. Adjust T-shape proportions by modifying ratios above
# 2. Increase core utilization further
# 3. Add congestion-specific constraints:
#    set_congestion_options -max_util 0.6 -coordinate [list $stem_left_x $core_lly $stem_right_x $top_bar_start_y]

# 4. Create specific placement constraints for problematic paths:
#    set_fp_placement_strategy -virtual_IPO on 
#    set_fp_placement_strategy -congestion_effort high

# 5. If still congested, re-run placement:
#    create_fp_placement -incremental

# 6. Consider increasing floorplan area if T-shape is too constraining:
#    create_floorplan -core_utilization 0.45 \
#        -start_first_row -flip_first_row \
#        -left_io2core 12.4 -bottom_io2core 12.4 -right_io2core 12.4 -top_io2core 12.4

save_mw_cel -as ${design}_2_fp_tshape

puts "T-shaped floorplan completed and saved as ${design}_2_fp_tshape"

##################################################
########### 3. POWER NETWORK #####################
##################################################

## Defining Logical POWER/GROUND Connections
############################################
derive_pg_connection 	 -power_net VDD		\
			 -ground_net VSS	\
			 -power_pin VDD		\
			 -ground_pin VSS	


## Define Power Ring 
####################
set_fp_rail_constraints  -set_ring -nets  {VDD VSS}  \
                         -horizontal_ring_layer { metal7 metal9 } \
                         -vertical_ring_layer { metal8 metal10 } \
			 -ring_spacing 0.8 \
			 -ring_width 5 \
			 -ring_offset 0.8 \
			 -extend_strap core_ring

## Define Power Mesh 
####################
set_fp_rail_constraints -add_layer  -layer metal10 -direction vertical   -max_strap 128 -min_strap 20 -min_width 2.5 -spacing minimum
set_fp_rail_constraints -add_layer  -layer metal9  -direction horizontal -max_strap 128 -min_strap 20 -min_width 2.5 -spacing minimum
set_fp_rail_constraints -add_layer  -layer metal8  -direction vertical   -max_strap 128 -min_strap 20 -min_width 2.5 -spacing minimum
set_fp_rail_constraints -add_layer  -layer metal7  -direction horizontal -max_strap 128 -min_strap 20 -min_width 2.5 -spacing minimum
set_fp_rail_constraints -add_layer  -layer metal6  -direction vertical   -max_strap 128 -min_strap 20 -min_width 2.5 -spacing minimum

#set_fp_rail_constraints -add_layer  -layer metal10 -direction vertical   -max_pitch 12 -min_pitch 12 -min_width 5 -spacing minimum
#set_fp_rail_constraints -add_layer  -layer metal9  -direction horizontal -max_pitch 12 -min_pitch 12 -min_width 5 -spacing minimum
#set_fp_rail_constraints -add_layer  -layer metal8  -direction vertical   -max_pitch 12 -min_pitch 12 -min_width 5 -spacing minimum
#set_fp_rail_constraints -add_layer  -layer metal7  -direction horizontal -max_pitch 12 -min_pitch 12 -min_width 5 -spacing minimum
#set_fp_rail_constraints -add_layer  -layer metal6  -direction vertical   -max_pitch 12 -min_pitch 12 -min_width 5 -spacing minimum


set_fp_rail_constraints -set_global

## Creating virtual PG pads
# you can create them with gui. Preroute > Create Virtual Power Pad
# Enhanced Virtual Power Pad Creation Script
# Usage: Modify the parameters below to increase number of pads

# Get die area coordinates
set die_area [get_attribute [get_die_area] boundary]
set llx [lindex [lindex $die_area 0] 0]
set lly [lindex [lindex $die_area 0] 1]
set urx [lindex [lindex $die_area 2] 0]
set ury [lindex [lindex $die_area 2] 1]

# CONFIGURATION PARAMETERS - Modify these to increase pads
set pads_per_side 10  ; # Increased from 7 to 10 pads per side

# Extended pad list with more pads
set pad_list {
    {VSS vpad_vss_1} {VSS vpad_vss_2} {VSS vpad_vss_3} {VSS vpad_vss_4}
    {VSS vpad_vss_5} {VSS vpad_vss_6} {VSS vpad_vss_7} {VSS vpad_vss_8}
    {VSS vpad_vss_9} {VSS vpad_vss_10} {VSS vpad_vss_11} {VSS vpad_vss_12}
    {VSS vpad_vss_13} {VSS vpad_vss_14} {VSS vpad_vss_15} {VSS vpad_vss_16}
    {VSS vpad_vss_17} {VSS vpad_vss_18} {VSS vpad_vss_19} {VSS vpad_vss_20}
    {VDD vpad_vdd_1} {VDD vpad_vdd_2} {VDD vpad_vdd_3} {VDD vpad_vdd_4}
    {VDD vpad_vdd_5} {VDD vpad_vdd_6} {VDD vpad_vdd_7} {VDD vpad_vdd_8}
    {VDD vpad_vdd_9} {VDD vpad_vdd_10} {VDD vpad_vdd_11} {VDD vpad_vdd_12}
    {VDD vpad_vdd_13} {VDD vpad_vdd_14} {VDD vpad_vdd_15} {VDD vpad_vdd_16}
    {VDD vpad_vdd_17} {VDD vpad_vdd_18} {VDD vpad_vdd_19} {VDD vpad_vdd_20}
}

# Calculate spacing and remove existing virtual pins
set total_pads [llength $pad_list]
set y_range [expr {$ury - $lly}]
set x_range [expr {$urx - $llx}]
set y_spacing [expr {$y_range / ($pads_per_side + 1)}]
set x_spacing [expr {$x_range / ($pads_per_side + 1)}]

# Remove existing virtual pins
remove_physical_pins [get_physical_pins -filter "pin_type == virtual"]

puts "Creating $total_pads virtual power pads with $pads_per_side pads per side"
puts "Die area: ($llx, $lly) to ($urx, $ury)"
puts "Spacing: X=$x_spacing, Y=$y_spacing"

set pad_idx 0

# Left side pads
puts "\n=== Placing LEFT side pads ==="
for {set i 1} {$i <= $pads_per_side && $pad_idx < $total_pads} {incr i} {
    set net [lindex [lindex $pad_list $pad_idx] 0]
    set pad_name [lindex [lindex $pad_list $pad_idx] 1]
    set y_pos [expr {$lly + ($i * $y_spacing)}]
    create_fp_virtual_pad -net $net -point [list $llx $y_pos]
    puts "Placed $pad_name ($net) at ($llx, $y_pos)"
    incr pad_idx
}

# Right side pads
puts "\n=== Placing RIGHT side pads ==="
for {set i 1} {$i <= $pads_per_side && $pad_idx < $total_pads} {incr i} {
    set net [lindex [lindex $pad_list $pad_idx] 0]
    set pad_name [lindex [lindex $pad_list $pad_idx] 1]
    set y_pos [expr {$lly + ($i * $y_spacing)}]
    create_fp_virtual_pad -net $net -point [list $urx $y_pos]
    puts "Placed $pad_name ($net) at ($urx, $y_pos)"
    incr pad_idx
}

# Bottom side pads
puts "\n=== Placing BOTTOM side pads ==="
for {set i 1} {$i <= $pads_per_side && $pad_idx < $total_pads} {incr i} {
    set net [lindex [lindex $pad_list $pad_idx] 0]
    set pad_name [lindex [lindex $pad_list $pad_idx] 1]
    set x_pos [expr {$llx + ($i * $x_spacing)}]
    create_fp_virtual_pad -net $net -point [list $x_pos $lly]
    puts "Placed $pad_name ($net) at ($x_pos, $lly)"
    incr pad_idx
}

# Top side pads
puts "\n=== Placing TOP side pads ==="
for {set i 1} {$i <= $pads_per_side && $pad_idx < $total_pads} {incr i} {
    set net [lindex [lindex $pad_list $pad_idx] 0]
    set pad_name [lindex [lindex $pad_list $pad_idx] 1]
    set x_pos [expr {$llx + ($i * $x_spacing)}]
    create_fp_virtual_pad -net $net -point [list $x_pos $ury]
    puts "Placed $pad_name ($net) at ($x_pos, $ury)"
    incr pad_idx
}

puts "\n=== Summary ==="
puts "Total pads placed: $pad_idx"
puts "Remaining pads in list: [expr {$total_pads - $pad_idx}]"

# Optional: Report pad distribution
set vss_count 0
set vdd_count 0
foreach pad $pad_list {
    if {[lindex $pad 0] == "VSS"} {
        incr vss_count
    } else {
        incr vdd_count
    }
}
puts "VSS pads: $vss_count, VDD pads: $vdd_count"
synthesize_fp_rail  -nets {VDD VSS} -synthesize_power_plan -target_voltage_drop 22 -voltage_supply 1.1 -power_budget 500
## Analyze IR-drop; Modify power network constraints and re-synthesize, as needed.
## Max IR is 2% of Nominal Supply. In our case, 0.02 x 1.1v= 22mv

commit_fp_rail

set_preroute_drc_strategy -max_layer metal6
preroute_standard_cells -fill_empty_rows -remove_floating_pieces

## If you want to remove power and recreate it
#remove_net_shape  [get_net_shapes -of_objects [get_nets -all "VSS VDD"]]
#remove_via  [get_vias -of_objects [get_nets -all "VSS VDD"]]
## MAy need => remove_fp_virtual_pad -all

## Analyze IR-drop; Modify power network constraints and re-synthesize, as needed.
analyze_fp_rail  -nets {VDD VSS} -power_budget 500 -voltage_supply 1.1


## Final Floorplan Assessment
create_fp_placement -incremental all; # Updates fp placement after PG mesh creation.
#### Analyze Congestion
#### Analyze Timing


## Add Well Tie Cells
#####################
add_tap_cell_array -master   TAP \
     		   -distance 30 \
     		   -pattern  stagger_every_other_row

save_mw_cel -as ${design}_3_power

##############################################
########### 4. Placement #####################
##############################################
puts "start_place"

## CHECKS
#########
report_ignored_layers ; # To Make sure they are as wanted.
check_physical_design -stage pre_place_opt
check_physical_constraints

## CONSTRAINTS 
##############
## Here, We define more constraints on your design that are related to placement stage.

#### Scenario Creation ####create_scenario pw
#### Scenario Creation ####set_operating_conditions worst_low
#### Scenario Creation ####set_tlu_plus_files -max_tluplus $tlupmax \
#### Scenario Creation ####                   -min_tluplus $tlupmin \
#### Scenario Creation ####     		   -tech2itf_map $tech2itf
#### Scenario Creation ####
#### Scenario Creation ####set_scenario_options -leakage_power true; #If we need to optimize leakage power, more effective for multi-Vth designs.
#### Scenario Creation ####set power_default_toggle_rate 0.003
#### Scenario Creation ####set_scenario_options -dynamic_power true
#### Scenario Creation ####
#### Scenario Creation ####source  ../syn/cons/cons.tcl
#### Scenario Creation ####set_propagated_clock [get_clocks clk]
#### Scenario Creation ####
#### Scenario Creation ####set_optimize_pre_cts_power_options -low_power_placement true
#### Scenario Creation ####
#### Scenario Creation ####report_scenario_options


## INITIAL PLACEMENT
####################
## Initial Placement can be done using the following command using any of its target options 
#place_opt -area_recovery |-power |-congestion|
place_opt

## ASSESSMENT
#############
## Open Congestion Map. == > If congested, improve congestion similar to floorplanning.
## Report Timing 

## FIXES
########
# For seriuos congestion issue use the following commands:
#   set placer_enable_enhanced_router TRUE; # enabling the actual GR instead of GR estimator. Increased run time!
#   refine_placement ==> Optimizes congestion only

# If there are violating timing paths, apply optimization -focus- as needed: 
#   report_path_group
#   group_path -name clk -critical_range 1 -weight 5


## OPTIMIZATION
###############
# psynopt -area_recovery |-power| |-congestion| 
psynopt

#The  psynopt  command  performs incremental preroute or postroute opti-
#mization on the current design. Performs incremental timing-driven  (setup timing, by default) logic optimization with placement legalization.
# It considers other targets using different options
# ex : psynopt -no_design_rule | -only_design_rule | -size_only ==> Used for Focused placment optimization

## FINAL ASSESSMENT
###################

check_legality
## If no legalized cells => legalize_placement -effort high -incremental 
# Check Congestion
# Check Timing 
# report_design_physical -utilization

# DEFINING POWER/GROUND NETS AND PINS			 
derive_pg_connection     -power_net VDD		\
			 -ground_net VSS	\
			 -power_pin VDD		\
			 -ground_pin VSS	

## Tie fixed values
set tie_pins [get_pins -all -filter "constant_value == 0 || constant_value == 0 && name !~ V* && is_hierarchical == false "]

derive_pg_connection 	 -power_net VDD		\
			 -ground_net VSS	\
			 -tie

if {[sizeof_collection $tie_pins] > 0 } {
	connect_tie_cells -objects $tie_pins \
                  -obj_type port_inst \
		  -tie_low_lib_cell  */LOGIC0_X1 \
		  -tie_high_lib_cell */LOGIC1_X1
}




puts "finish_place"

save_mw_cel -as ${design}_4_placed

##############################################
########### 5. CTS       #####################
##############################################

puts "start_cts"

## CHECKS
#########
check_physical_design -stage pre_clock_opt 
check_clock_tree 
report_clock_tree


## CONSTRAINTS 
##############
## Here, We define more constraints on your design that are related to CTS stage.

set_driving_cell -lib_cell BUF_X16 -pin Z [get_ports clk]
###OR
# set_input_transition -rise 0.3 [get_ports clk]
# set_input_transition -fall 0.2 [get_ports clk]


#### Set Clock Exceptions


### Set Clock Control/Targets
set_clock_tree_options \
                -clock_trees clk \
		-target_early_delay 0.1 \
		-target_skew 0.5 \
		-max_capacitance 300 \
		-max_fanout 10 \
		-max_transition 0.3

set_clock_tree_options -clock_trees clk \
		-buffer_relocation true \
		-buffer_sizing true \
		-gate_relocation true \
		-gate_sizing true 

## Selection of CTS cells
set_clock_tree_references -references [get_lib_cells */CLKBUF*] 
#set_clock_tree_references -references [get_lib_cells */BUF*] 
#set_clock_tree_references -references [get_lib_cells */INV*] 

## Selection of CTO cells
#set_clock_tree_references -sizing_only -references "BEST_PRACTICE_buffers_for_CTS_CTO_sizing"
#set_clock_tree_references -delay_insertion_only -references "BEST_PRACTICE_cels_for_CTS_CTO_delay_insertion" 



### Set Clock Physical Constraints
## Clock Non-Default Ruls (NDR) - Set it to be double width and double spacing 
define_routing_rule my_route_rule  \
  -widths   {metal3 0.14 metal4 0.28 metal5 0.28} \
  -spacings {metal3 0.14 metal4 0.28 metal5 0.28} 

set_clock_tree_options -clock_trees clk \
                       -routing_rule my_route_rule  \
		       -layer_list "metal3 metal4 metal5"

## To avoid NDR at clock sinks
set_clock_tree_options -use_default_routing_for_sinks 1

report_clock_tree -settings


## Clock Tree : Synhtesis, Optimization, and Routing
####################################################
## The 3 steps can be done with the combo command clock_opt. But below, we do them individually.

## 1- CTS 
clock_opt -only_cts -no_clock_route
## analyze
    report_design_physical -utilization
    report_clock_tree -summary ; # reports for the clock tree, regardless of relation between FFs
    report_clock_tree
    report_clock_timing -type summary ; # reports for the clock tree, considering relation between FFs
    report_timing
    report_timing -delay_type min
    report_constraints -all_violators -max_delay -min_delay
    # Check Congestion
    # Check Timing


## 2- CTO
## To Consider Hold Fix -- Design Dependent
#   set_fix_hold [all_clocks]
#   set_fix_hold_options -prioritize_tns
clock_opt -only_psyn -no_clock_route
#analyze


## 3- Clock Tree Routing
route_group -all_clock_nets
#analyze


## If any issue at analysis, update CT constraints 
##################################################

# DEFINING POWER/GROUND NETS AND PINS			 
derive_pg_connection     -power_net VDD		\
			 -ground_net VSS	\
			 -power_pin VDD		\
			 -ground_pin VSS	
			 
save_mw_cel -as ${design}_5_cts

puts "finish_cts"

##############################################
########### 6. Routing   #####################
##############################################

## Before starting to route, you should add spare cells
insert_spare_cells -lib_cell {NOR2_X4 NAND2_X4} \
		   -num_instances 20 \
		   -cell_name SPARE_PREFIX_NAME \
		   -tie

set_dont_touch  [all_spare_cells] true
set_attribute [all_spare_cells]  is_soft_fixed true

##############################################

puts "start_route"

check_physical_design -stage pre_route_opt; # dump check_physical_design result to file ./cpd_pre_route_opt_*/index.html
all_ideal_nets
all_high_fanout -nets -threshold 100
check_routeability


set_delay_calculation_options -arnoldi_effort low

#Defines the delay model used to compute a timing arc delay value for a cell or net
#set_delay_calculation_options -preroute     elmore | awe (Asymptotic Waveform Evaluation)
#                              -routed_clock elmore | arnoldi
#			       -postroute    elmore | arnoldi
#			       -awe_effort     low | medium | high
#			       -arnoldi_effort low | medium | high
			      

set_route_options -groute_timing_driven true \
	          -groute_incremental true \
	          -track_assign_timing_driven true \
	          -same_net_notch check_and_fix 

set_si_options -route_xtalk_prevention true\
	       -delta_delay true \
	       -min_delta_delay true \
	       -static_noise true\
	       -timing_window true 


## route_opt : global, track, and detail routing, S&R, logic and placement optimizations with ECO routing
##             End goal: Design that meets timing, crosstalk and route DRC rules

#route_opt -effort high \
#	  -stage track        : which stage to run optimization after
#	  -xtalk_reduction    : to reduce crosstalk in routing 
#	  -incremental        : to improve results of a routed design.
#	  -initial_route_only : This is to avoid full routing and post-routing optimizations. Only do the basic steps.

## To Consider Hold Fix
#   set_fix_hold_options -prioritize_tns
   set_fix_hold [all_clocks]
   set_prefer -min  [get_lib_cells "*/BUF_X2 */BUF_X1"]
   set_fix_hold_options -preferred_buffer


route_opt
psynopt  -only_hold_time -congestion
route_zrt_eco -open_net_driven true

verify_zrt_route
route_zrt_detail -incremental true -initial_drc_from_input true

insert_zrt_redundant_vias
verify_zrt_route
route_zrt_detail -incremental true -initial_drc_from_input true

derive_pg_connection     -power_net VDD		\
			 -ground_net VSS	\
			 -power_pin VDD		\
			 -ground_pin VSS	




#report_noise
#report_timing -crosstalk_delta


save_mw_cel -as ${design}_6_routed

puts "finish_route"


##############################################
########### 7. Finishing #####################
##############################################


insert_stdcell_filler -cell_without_metal {FILLCELL_X32 FILLCELL_X16 FILLCELL_X8 FILLCELL_X4 FILLCELL_X2 FILLCELL_X1} \
	-connect_to_power VDD -connect_to_ground VSS

 

derive_pg_connection     -power_net VDD		\
			 -ground_net VSS	\
			 -power_pin VDD		\
			 -ground_pin VSS	

save_mw_cel -as ${design}_7_finished

save_mw_cel -as ${design}

##############################################
########### 8. Checks and Outputs ############
##############################################

verify_zrt_route
verify_lvs -ignore_floating_port -ignore_floating_net \
           -check_open_locator -check_short_locator

set_write_stream_options -map_layer $sc_dir/tech/strmout/FreePDK45_10m_gdsout.map \
                         -output_filling fill \
			 -child_depth 20 \
			 -output_outdated_fill  \
			 -output_pin  {text geometry}

write_stream -lib $design \
                  -format gds\
		  -cells $design\
		  ./output/${design}.gds



define_name_rules  no_case -case_insensitive
change_names -rule no_case -hierarchy
change_names -rule verilog -hierarchy
set verilogout_no_tri	 true
set verilogout_equation  false


write_verilog -pg -no_physical_only_cells ./output/${design}_icc.v
write_verilog -no_physical_only_cells ./output/${design}_icc_nopg.v

extract_rc
write_parasitics -output {./output/mips_16.spef}


close_mw_cel
close_mw_lib

exit

