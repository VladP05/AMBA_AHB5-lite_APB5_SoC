# AMBA AHB-to-APB Subsystem

Small SoC bus interconnect design written in SystemVerilog. It connects an AHB-Lite bus master to an internal SRAM and two APB peripherals via an AHB-to-APB bridge.

## Modules

### 1. AHB-Lite SRAM
- 1 KB internal memory (256 words x 32 bits).
- Supports Byte, Half-word, and Word read/write operations with proper byte-lane alignment.
- Standard AHB 2-cycle error response
- Stalls correctly when `HREADY_IN` is pulled low by another slave.

### 2. AHB-to-APB Bridge
- Translates AHB pipelined transfers into APB `SETUP` and `ACCESS` phases.
- Manages wait states via `PREADY` backpressure to `HREADYOUT`.
- Forwards APB transfer errors (`PSLVERR`) as 2-cycle `HRESP` errors on AHB.

### 3. APB Slaves
- **GPIO:** Basic register-controlled I/O port.
- **Timer):** 32-bit counter/timer peripheral.

## Memory Map

| Module | Address Range | Size | Protocol |
|---|---|---|---|
| SRAM | `0x0000_0000 - 0x0000_03FF` | 1 KB | AHB-Lite |
| APB GPIO | `0x4000_0000 - 0x4000_007F` | 128 B | APB |
| APB Timer | `0x4000_0080 - 0x4000_00FF` | 128 B | APB |
