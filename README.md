# Replica1-SDRAM: Apple 1 Clone in VHDL

This experimental project is designed to test the implementation of an SDRAM controller and its integration with classic CPU cores.

## Core Objectives

- **SDRAM Controller**: Developing and refining a custom controller.
- **SRAM to SDRAM Bridge**: Implementing a bridge for seamless memory access.
- **Clock Stretcher**: Permitting wait states on the 6502 core.
- **Performance Benchmarking**: Testing the maximum stable clock speed of the CPU core.

## Architecture

The initial SDRAM controller is intentionally simple, with planned iterative improvements for performance. CPU cores (6502, 6800, 6809) utilize an added RDY/MRDY signal managed via a clock stretcher.

## Development Roadmap

**Phase 1**: Maintain the majority of the Replica1 in EBR, implementing a specific SDRAM window at $E000-$EFFF for memory testing.

**Phase 2**: Transition all RAM to SDRAM, utilizing EBR exclusively for ROM blocks.

## Performance Goals

- **Target CPU Speed**: 10-14 MHz.
- **Potential Upside**: Higher speeds may be achieved if the SDRAM clock is pushed beyond 100 MHz (aiming for 120-133 MHz).

## Development Log

| Date | Milestone / Update |
|------|-------------------|
| 2026/01/24 | Initial Success: Configured with Wozmon and 48k EBR RAM. SDRAM window ($E000-$EFFF) passed infinite loop tests at 1, 2, and 5 MHz. At 10 MHz, it requires a 120 MHz SDRAM clock. |
| 2026/01/25 | Stability Issues: Added clock stretcher and fixed connection bugs. Memory tests show inconsistent pass/fail results at different speeds. |
| 2026/02/01 | Bus Analysis: Created a bus tester config. Discovered that phi1 and phi2 were inverted due to lack of documentation on the CPU core. |
| 2026/02/02 | Clock Generation: Replaced the old clock stretcher with cpu_clock_gen for standardized clocking and mrdy handling across all CPUs. |
| 2026/02/03 | CPU Expansion: Added T65, MX65, and R65C02 cores. Updated all CPU wrappers to use the new clock generator to abstract core differences. |
| 2026/02/04 | Bridge Testing: Created a "fake" SDRAM controller using EBR to isolate bugs. Confirmed the SRAM-to-SDRAM bridge works correctly. |
| 2026/02/05 | SDRAM Controller: Initialization, refresh, and read functions are working. Identified a bug where writes occur at addr + 1. |
| 2026/02/07 | Refactoring: Completed a total rewrite of the SDRAM controller using a two-signal state machine (current_state and next_state). |
| 2026/02/09 | Architecture Split: Split treatment into two processes (one clocked, one combinatorial). Still troubleshooting the addr + 1 write bug. |
| 2026/02/10 | Breakthrough: Fixed the write address bug. Successfully passed 10 million R/W cycles at 10 MHz CPU speed and 75 MHz SDRAM speed. |