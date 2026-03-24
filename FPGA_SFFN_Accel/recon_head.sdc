# Create a clock constraint for the 'clk' port at 50MHz (20ns period)
create_clock -name clk -period 20.000 [get_ports {clk}]

# Automatically derive clock uncertainty (standard for Cyclone V)
derive_clock_uncertainty