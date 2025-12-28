set_property PACKAGE_PIN L16 [get_ports clk]
set_property PACKAGE_PIN Y16 [get_ports reset]
set_property PACKAGE_PIN V12 [get_ports tx]
set_property PACKAGE_PIN W16 [get_ports rx]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
create_clock -name clk -period 10.000 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]


set_false_path -from [get_ports reset]
set_property IOB TRUE [get_cells uart_module/transmitter/tx_reg]


#set_output_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports {TX}]
#set_input_delay -clock [get_clocks CLK] -min -add_delay 0.000 [get_ports {RX}]

#set_output_delay -clock [get_clocks CLK] -max -add_delay 0.000 [get_ports {TX}]
#set_input_delay -clock [get_clocks CLK] -max -add_delay 0.000 [get_ports {RX}]