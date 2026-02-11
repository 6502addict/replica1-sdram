# Replica1-SDRAM: Apple 1 Clone in VHDL

This experimental project is designed to test the implementation of an SDRAM controller and its integration with classic CPU cores.

## ⚖️ License & Commercial Use

This project is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

- **Individual/Non-Commercial:** Free to use, share, and adapt!
- **Commercial Use:** Forbidden under this license. 

**Want to use this code commercially?** Please contact **Didier Derny** at didier@aida.org to discuss a commercial license.

## 🎓 Educational Use & "Theory of Operation"
This project was born out of frustration with the lack of documented, readable SDRAM controllers available online. Most existing solutions are either "black boxes" or lack clear explanations.

Heavily Documented: The bridge and controller include a "Theory of Operation" within the comments to explain why specific timings and state transitions are used.

For Students: You are encouraged to use this code for learning, university projects, and experimentation.

For Hobbyists: If you are building a Replica 1 or similar 6502/6800 system, this is designed to be readable so you can adapt it to your specific hardware.

Note on the License: This project uses the CC BY-NC-SA 4.0 license. This means it will always remain free for the community. If you improve the cache or the controller, you must share those improvements so others can learn from them too!

A quick tip on "Timing Closure" for your users:
Since you’ve written this for Quartus, students might try to compile it for different FPGAs (like a Cyclone II vs a Cyclone IV). Because SDRAM is so sensitive to the Phase-Locked Loop (PLL) settings:

Does your code include the .sdc (Synopsys Design Constraints) file?

If not, you might want to add a small note about the clock phase shift (usually -3ns or -90 degrees) needed to talk to the SDRAM chip reliably. That is usually the "final boss" that stops students from getting their hardware to work!

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
| 2026/02/11 | Completed write-through cache implementation (1KB) with 47-52% hit rate. Unified bridge architecture allows runtime cache enable/disable. Full documentation added: theory of operation, state-by-state comments, CC BY-NC-SA 4.0 license. SDRAM controller validated in both auto-precharge and manual modes. All components production-ready at 10 MHz. |
