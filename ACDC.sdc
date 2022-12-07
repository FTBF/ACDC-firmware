
 
# WARNING: Expected ENABLE_CLOCK_LATENCY to be set to 'ON', but it is set to 'OFF'
#          In SDC, create_generated_clock auto-generates clock latency
#
# ------------------------------------------
#
# Create generated clocks based on PLLs

#
# ------------------------------------------
#-waveform {0  12.500} 

# Original Clock Setting Name: master_clock0
create_clock 	-period "30.000 ns"  [get_ports clockIn.localOsc]
create_clock 	-period  "8.000 ns"  [get_ports clockIn.accOsc]
create_clock 	-period "25.000 ns"  [get_ports clockIn.jcpll]
create_clock 	-period "10.000 ns"  [get_ports clockIn.wr100]
create_clock 	-period "25000.000 ns"  [get_ports {jcpll_ctrl.spi_clock}]
				
create_clock -period 40MHz 	[get_ports PSEC4_out[0].readClock]
create_clock -period 40MHz 	[get_ports PSEC4_out[1].readClock]
create_clock -period 40MHz 	[get_ports PSEC4_out[2].readClock]					
create_clock -period 40MHz 	[get_ports PSEC4_out[3].readClock]
create_clock -period 40MHz 	[get_ports PSEC4_out[4].readClock]

create_clock -period 40MHz 	-name PSEC4_rdclk_virt_0
create_clock -period 40MHz 	-name PSEC4_rdclk_virt_1
create_clock -period 40MHz 	-name PSEC4_rdclk_virt_2
create_clock -period 40MHz 	-name PSEC4_rdclk_virt_3
create_clock -period 40MHz 	-name PSEC4_rdclk_virt_4

set_clock_uncertainty -from { PSEC4_rdclk_virt_0 } -setup 0.25
set_input_delay -clock PSEC4_rdclk_virt_0 -min  5.0 [get_ports {PSEC4_in[0].data*}]
set_input_delay -clock PSEC4_rdclk_virt_0 -max 12.0 [get_ports {PSEC4_in[0].data*}]

set_clock_uncertainty -from { PSEC4_rdclk_virt_1 } -setup 0.25
set_input_delay -clock PSEC4_rdclk_virt_1 -min  5.0 [get_ports {PSEC4_in[1].data*}]
set_input_delay -clock PSEC4_rdclk_virt_1 -max 12.0 [get_ports {PSEC4_in[1].data*}]

set_clock_uncertainty -from { PSEC4_rdclk_virt_2 } -setup 0.25
set_input_delay -clock PSEC4_rdclk_virt_2 -min  5.0 [get_ports {PSEC4_in[2].data*}]
set_input_delay -clock PSEC4_rdclk_virt_2 -max 12.0 [get_ports {PSEC4_in[2].data*}]

set_clock_uncertainty -from { PSEC4_rdclk_virt_3 } -setup 0.25
set_input_delay -clock PSEC4_rdclk_virt_3 -min  5.0 [get_ports {PSEC4_in[3].data*}]
set_input_delay -clock PSEC4_rdclk_virt_3 -max 12.0 [get_ports {PSEC4_in[3].data*}]

set_clock_uncertainty -from { PSEC4_rdclk_virt_4 } -setup 0.25
set_input_delay -clock PSEC4_rdclk_virt_4 -min  5.0 [get_ports {PSEC4_in[4].data*}]
set_input_delay -clock PSEC4_rdclk_virt_4 -max 12.0 [get_ports {PSEC4_in[4].data*}]

#create_clock [get_ports lvds_rx_in(1)]

#create_generated_clock -multiply_by 8 -source clk_system_40 -name CLKmain:inst6|altpll1:inst2|altpll:altpll_component|altpll1_altpll:auto_generated|wire_pll1_clk[0]

derive_pll_clocks -use_tan_name		

derive_clock_uncertainty

set_false_path -from {dataHandler:dataHandler_map|handshake_sync:\psec_sync_loop:*:handshake_sync_fifoOcc|src_params_latch*} -to {dataHandler:dataHandler_map|handshake_sync:\psec_sync_loop:*:handshake_sync_fifoOcc|dest_params*}
set_false_path -from {dataHandler:dataHandler_map|handshake_sync:*|src_params_latch*} -to {dataHandler:dataHandler_map|handshake_sync:*|dest_params*}

# ---------------------------------------------

# ** Clock Latency
#    -------------

# ** Clock Uncertainty
#    -----------------

# ** Multicycles
#    -----------
# ** Cuts
#    ----

# ** Input/Output Delays
#    -------------------

#set_max_delay -from [get_ports {PSEC4_in[*].trig[*]}] -to [get_registers {trigger:trigger_map|trig_latch}] 10.000	
#set_max_delay -from [get_keepers {trigger:trigger_map|trig_latch*}] -to [get_keepers {PSEC4_out*.extTrig}] 5.000


# ** Tpd requirements
#    ----------------

# ** Setup/Hold Relationships
#    ------------------------

# ** Tsu/Th requirements
#    -------------------


# ** Tco/MinTco requirements
#    -----------------------



# ---------------------------------------------

