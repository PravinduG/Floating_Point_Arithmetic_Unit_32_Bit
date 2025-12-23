set_property PACKAGE_PIN L16 [get_ports clk]
set_property PACKAGE_PIN Y16 [get_ports reset]
set_property PACKAGE_PIN V12 [get_ports tx]
set_property PACKAGE_PIN W16 [get_ports rx]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
create_clock -name clk -period 20.000 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]


set_false_path -from [get_ports reset]