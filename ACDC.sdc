
 
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
create_clock 	-period "40.000 ns"  [get_ports clockIn.accOsc]
create_clock 	-period "25.000 ns"  [get_ports clockIn.jcpll]
create_clock 	-period "10.000 ns"  [get_ports clockIn.wr100]
create_clock 	-period "25000.000 ns"  [get_ports {jcpll_ctrl.spi_clock}]
				
create_clock -period 40MHz 	[get_ports PSEC4_out(0).readClock]					
create_clock -period 40MHz 	[get_ports PSEC4_out(1).readClock]
create_clock -period 40MHz 	[get_ports PSEC4_out(2).readClock]					
create_clock -period 40MHz 	[get_ports PSEC4_out(3).readClock]
create_clock -period 40MHz 	[get_ports PSEC4_out(4).readClock]

#create_clock [get_ports lvds_rx_in(1)]

#create_generated_clock -multiply_by 8 -source clk_system_40 -name CLKmain:inst6|altpll1:inst2|altpll:altpll_component|altpll1_altpll:auto_generated|wire_pll1_clk[0]

derive_pll_clocks -use_tan_name		

derive_clock_uncertainty		

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




# ** Tpd requirements
#    ----------------

# ** Setup/Hold Relationships
#    ------------------------

# ** Tsu/Th requirements
#    -------------------


# ** Tco/MinTco requirements
#    -----------------------



# ---------------------------------------------

