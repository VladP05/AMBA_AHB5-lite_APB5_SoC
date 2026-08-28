# ADR 001: SRAM Optimization – Block RAM Inference and AHB-Lite Pipelining

## 1. Context and Initial Architecture
The initial implementation of the 1 KB SRAM module (256 words x 32 bits) utilized an asynchronous (combinational) read operation:

`assign hrdata = mem[haddr_reg[9:2]];`

## 2. Identified Issues
* **Logic Resource Explosion:** Dedicated on-chip FPGA memory blocks (Block RAM / BRAM) strictly require a clock edge for read operations. Because of the combinational read description, the synthesis tool (Vivado) could not infer dedicated BRAM primitives.
* **Hardware Overhead (Distributed Logic):**
  * **8,192 Flip-Flops (D-FFs)** were synthesized individually for every single memory bit.
  * **A massive 256:1 Multiplexer tree** was constructed across thousands of LUTs to route read data combinationally.
* **Timing & Performance Degradation:** The extensive combinational path caused severe routing congestion and drastically lowered the maximum achievable clock frequency (Fmax).

## 3. Implemented Solution
1. **Synchronous Read Architecture:** Moved the read operation into the sequential domain (`always_ff @(posedge clk)`) using the direct address bus (`haddr`) during the Address Phase:

`hrdata <= mem[haddr[9:2]];`

2. **Native AHB-Lite Pipeline Alignment:** The 1-cycle internal latency of synchronous Block RAM naturally aligns with the AHB-Lite bus pipeline (Address Phase at Cycle N -> Data Phase at Cycle N+1), sustaining 0 wait-state throughput.
3. **Read-After-Write (RAW) Hazard Resolution:** To prevent reading stale data when a read operation immediately targets the address written in the preceding cycle, an internal data forwarding bypass was implemented:

`if (hwrite_reg && (haddr[9:2] == haddr_reg[9:2])) begin`
    `hrdata <= hwdata;`
`end`

## 4. Results & Impact
* **Silicon Efficiency:** Reclaimed ~8,192 flip-flops and hundreds of LUTs by mapping the entire memory array into a single dedicated RAMB18E1/RAMB36E1 hardware block.
* **Higher Clock Frequency (Fmax):** Read routing is fully contained inside the memory primitive, eliminating large multiplexer logic depths and propagation delays.
* **Reduced Dynamic Power:** Eliminated redundant signal switching across thousands of distributed logic gates.