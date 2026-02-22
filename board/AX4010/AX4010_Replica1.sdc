# Clocks de base
create_clock -name clk -period 20.000 [get_ports {clk}]

# Clocks générés par le PLL
create_generated_clock -name clock_30mhz \
    -source [get_pins {mclk|altpll_component|auto_generated|pll1|inclk[0]}] \
    -divide_by 5 -multiply_by 3 \
    [get_pins {mclk|altpll_component|auto_generated|pll1|clk[0]}]

create_generated_clock -name clock_sdram \
    -source [get_pins {mclk|altpll_component|auto_generated|pll1|inclk[0]}] \
    -multiply_by 2 \
    [get_pins {mclk|altpll_component|auto_generated|pll1|clk[2]}]

# Contraintes SDRAM (CRITIQUE!)
set_output_delay -clock clock_sdram -max 1.5 [get_ports {sdram_addr[*]}]
set_output_delay -clock clock_sdram -min -0.8 [get_ports {sdram_addr[*]}]
set_output_delay -clock clock_sdram -max 1.5 [get_ports {sdram_ba[*]}]
set_output_delay -clock clock_sdram -min -0.8 [get_ports {sdram_ba[*]}]
set_output_delay -clock clock_sdram -max 1.5 [get_ports {sdram_*_n}]
set_output_delay -clock clock_sdram -min -0.8 [get_ports {sdram_*_n}]
set_output_delay -clock clock_sdram -max 1.5 [get_ports {sdram_dqm[*]}]
set_output_delay -clock clock_sdram -min -0.8 [get_ports {sdram_dqm[*]}]

# Données bidirectionnelles
set_input_delay -clock clock_sdram -max 5.4 [get_ports {sdram_dq[*]}]
set_input_delay -clock clock_sdram -min 2.5 [get_ports {sdram_dq[*]}]
set_output_delay -clock clock_sdram -max 1.5 [get_ports {sdram_dq[*]}]
set_output_delay -clock clock_sdram -min -0.8 [get_ports {sdram_dq[*]}]

# Multicycle pour CAS latency
set_multicycle_path -from [get_clocks {clock_sdram}] -setup -end 2
set_multicycle_path -from [get_clocks {clock_sdram}] -hold -end 1

# Clocks asynchrones
set_clock_groups -asynchronous \
    -group [get_clocks {clk}] \
    -group [get_clocks {clock_30mhz}] \
    -group [get_clocks {clock_sdram}]