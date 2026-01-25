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

2026/01/24:   replica 1 sdram configured with wozmon / 48k ram ebr / standard console 115200bauds and nothing else... works !
				  the sdram window is implemented  between $E000 and $EFFF	a test-ram program test this ram area in an infinite loop
				  works at cpu speed 1, 2, 5 Mhz
				  once the sdram clock is pushed to 120Mhz it also pass at 10Mhz
				  now I'm trying to push the limit of the sdram clock strange behavior above 120 Mhz 
				  apparently the sdram need a power down to recover, I have to check the rest)
2026/01/25:   clock stretcher added,  
              fixed a strange bug with sdram connections
				  replaced sdram connection by registered connection