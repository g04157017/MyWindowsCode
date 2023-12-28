
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name XC6SLX25v1 -dir "F:/01FPGA_PRO/HighSpeedAcquisitionCard/PRO/planAhead_run_4" -part xc6slx25ftg256-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "F:/01FPGA_PRO/HighSpeedAcquisitionCard/PRO/top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {F:/01FPGA_PRO/HighSpeedAcquisitionCard/PRO} {../ip_core/fifo} {../ip_core/clk} }
add_files [list {../ip_core/fifo/rdfifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../ip_core/fifo/wrfifo.ncf}] -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_property target_constrs_file "top.ucf" [current_fileset -constrset]
add_files [list {top.ucf}] -fileset [get_property constrset [current_run]]
link_design
