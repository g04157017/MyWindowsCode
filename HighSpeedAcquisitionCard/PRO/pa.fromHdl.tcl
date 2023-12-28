
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name XC6SLX25v1 -dir "F:/01FPGA_PRO/HighSpeedAcquisitionCard/PRO/planAhead_run_3" -part xc6slx25ftg256-2
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "top.ucf" [current_fileset -constrset]
add_files [list {../ip_core/fifo/wrfifo.ngc}]
add_files [list {../ip_core/fifo/rdfifo.ngc}]
set hdlfile [add_files [list {../RTL/sdram/sdram_driver/sdram_data.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../RTL/sdram/sdram_driver/sdram_ctrl.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../RTL/sdram/sdram_driver/sdram_cmd.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../ip_core/fifo/wrfifo.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../ip_core/fifo/rdfifo.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../RTL/sdram/sdram_fifo_ctrl.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../RTL/sdram/sdram_driver/sdram_controller.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../RTL/sdram/sdram_top.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../RTL/sdram/sdram_test.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../ip_core/clk/pll_clk.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../RTL/top.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set_property top top $srcset
add_files [list {top.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {../ip_core/fifo/rdfifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../ip_core/fifo/wrfifo.ncf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx25ftg256-2
