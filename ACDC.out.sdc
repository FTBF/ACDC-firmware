## Generated SDC file "ACDC.out.sdc"

## Copyright (C) 2019  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 19.1.0 Build 670 09/22/2019 SJ Standard Edition"

## DATE    "Mon Aug 30 15:33:31 2021"

##
## DEVICE  "EP4CGX110DF27C7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clockIn.jcpll} -period 8.000 -waveform { 0.000 4.000 } [get_ports {clockIn.jcpll}]
create_clock -name {ClockGenerator:clockGen_map|serialClock} -period 1000.000 -waveform { 0.000 500.000 } [get_registers { ClockGenerator:clockGen_map|serialClock }]
create_clock -name {clockIn.localOsc} -period 25.000 -waveform { 0.000 12.500 } [get_ports { clockIn.localOsc }]
create_clock -name {ClockGenerator:clockGen_map|clock.timer} -period 1000000.000 -waveform { 0.000 500000.000 } [get_registers { ClockGenerator:clockGen_map|clock.timer }]
create_clock -name {LVDS_in[1]} -period 25.000 -waveform { 0.000 12.500 } [get_ports { LVDS_in[1] }]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 8 -divide_by 25 -master_clock {clockIn.jcpll} [get_pins {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 32 -divide_by 25 -master_clock {clockIn.jcpll} [get_pins {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 64 -divide_by 25 -master_clock {clockIn.jcpll} [get_pins {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {ClockGenerator:clockGen_map|serialClock}] -rise_to [get_clocks {ClockGenerator:clockGen_map|serialClock}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {ClockGenerator:clockGen_map|serialClock}] -fall_to [get_clocks {ClockGenerator:clockGen_map|serialClock}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ClockGenerator:clockGen_map|serialClock}] -rise_to [get_clocks {ClockGenerator:clockGen_map|serialClock}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ClockGenerator:clockGen_map|serialClock}] -fall_to [get_clocks {ClockGenerator:clockGen_map|serialClock}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockIn.localOsc}] -rise_to [get_clocks {ClockGenerator:clockGen_map|serialClock}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clockIn.localOsc}] -fall_to [get_clocks {ClockGenerator:clockGen_map|serialClock}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clockIn.localOsc}] -rise_to [get_clocks {clockIn.localOsc}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockIn.localOsc}] -fall_to [get_clocks {clockIn.localOsc}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockIn.localOsc}] -rise_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clockIn.localOsc}] -fall_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clockIn.localOsc}] -rise_to [get_clocks {ClockGenerator:clockGen_map|serialClock}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clockIn.localOsc}] -fall_to [get_clocks {ClockGenerator:clockGen_map|serialClock}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clockIn.localOsc}] -rise_to [get_clocks {clockIn.localOsc}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockIn.localOsc}] -fall_to [get_clocks {clockIn.localOsc}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockIn.localOsc}] -rise_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clockIn.localOsc}] -fall_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -rise_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -fall_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -rise_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -fall_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {LVDS_in[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {LVDS_in[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {LVDS_in[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {LVDS_in[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {LVDS_in[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {LVDS_in[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {LVDS_in[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {LVDS_in[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {LVDS_in[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {LVDS_in[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {LVDS_in[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {LVDS_in[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {LVDS_in[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {LVDS_in[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {LVDS_in[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {LVDS_in[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {LVDS_in[1]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {LVDS_in[1]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {LVDS_in[1]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {LVDS_in[1]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {ClockGenerator:clockGen_map|clock.timer}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {LVDS_in[1]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {LVDS_in[1]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {LVDS_in[1]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {LVDS_in[1]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {ClockGenerator:clockGen_map|serialClock}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {ClockGenerator:clockGen_map|serialClock}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {ClockGenerator:clockGen_map|serialClock}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {ClockGenerator:clockGen_map|serialClock}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {LVDS_in[1]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {LVDS_in[1]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {LVDS_in[1]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {LVDS_in[1]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {ClockGenerator:clockGen_map|serialClock}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {ClockGenerator:clockGen_map|serialClock}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {ClockGenerator:clockGen_map|serialClock}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {ClockGenerator:clockGen_map|serialClock}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {LVDS_in[1]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {LVDS_in[1]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {LVDS_in[1]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {LVDS_in[1]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clockGen_map|PLL_MAP|altpll_component|auto_generated|pll1|clk[0]}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

