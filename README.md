# Replica1-SDRAM - Apple 1 Clone in VHDL using SDRAM

This is an experimental project to test:
- A SDRAM controller
- A SRAM to SDRAM bridge
- A clock stretcher to permit wait states on the 6502 core
- The maximum speed that can be reached with the CPU core

## Architecture

The first version of the SDRAM controller is very simple and will be enhanced over time to improve performance.

The cores (6502/6800/6809) will have a RDY/MRDY signal added via a clock stretcher.

## Development Steps

**Step 1:** Keep most of Replica1 in EBR and add a SDRAM window at $E000-$EFFF for memory testing

**Step 2:** Once Step 1 is successful, implement all RAM in SDRAM, keeping only ROM blocks in EBR

## Performance Goals

Expected maximum CPU speed: 10-14 MHz
- Potentially higher if SDRAM clock can be pushed above 100 MHz (120-133 MHz)

