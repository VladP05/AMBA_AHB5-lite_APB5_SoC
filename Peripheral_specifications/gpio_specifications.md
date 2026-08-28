# APB 8-bit GPIO Controller Specification (`peripheral_slave2`)

## 1. Overview
The `peripheral_slave2` module is an 8-bit General-Purpose Input/Output (GPIO) controller integrated on an AMBA APB bus. It features configurable pin direction control, synchronized rising-edge event detection, per-pin interrupt masking, a Write-1-to-Clear (W1C) interrupt status register, and a centralized interrupt request (`irq`) output line.

---

## 2. Interface Signals

| Signal | Dir | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | `clk` | Primary system clock |
| `rst_n` | Input | 1 | Async | Active-low asynchronous reset |
| `paddr` | Input | 32 | `clk` | APB address bus |
| `pprot` | Input | 3 | `clk` | APB protection type |
| `psel` | Input | 1 | `clk` | APB slave select signal |
| `penable` | Input | 1 | `clk` | APB enable |
| `pwrite` | Input | 1 | `clk` | 1 = Write transaction, 0 = Read transaction |
| `pwdata` | Input | 32 | `clk` | APB write data bus |
| `pstrb` | Input | 4 | `clk` | APB byte-lane write strobes |
| `pready` | Output | 1 | `clk` | APB slave ready signal |
| `prdata` | Output | 32 | `clk` | APB read data bus |
| `pslverr` | Output | 1 | `clk` | APB slave error response |
| `gpio_in` | Input | 8 | `clk` | External GPIO input pins |
| `gpio_out` | Output | 8 | `clk` | GPIO output data lines |
| `gpio_oe` | Output | 8 | `clk` | GPIO output enable / direction lines |
| `irq` | Output | 1 | `clk` | Combined interrupt request output |

---

## 3. Register Map

| Offset | Register Name | Access | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x00` | **`DATAIN_REG`** | RO | `32'h0000_0000` | Raw pin input state (Write triggers `pslverr`) |
| `0x04` | **`DATAOUT_REG`** | R/W | `32'h0000_0000` | GPIO output data register |
| `0x08` | **`DIRECTION_REG`**| R/W | `32'h0000_0000` | GPIO direction / output enable register |
| `0x0C` | **`INT_EN_REG`** | R/W | `32'h0000_0000` | Interrupt enable mask register |
| `0x10` | **`INT_STATUS_REG`**| W1C / RO | `32'h0000_0000` | Interrupt status register (Write-1-to-Clear) |

---

## 4. Register Descriptions

### `DATAIN_REG` (Offset: `0x00`)
* **Reset Value:** `32'h0000_0000` (reflects live input state)
* **Access:** Read-Only (RO)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[7:0]` | `DATA_IN` | RO | **GPIO Pin Input State:** Reflects the logical value currently present on the `gpio_in[7:0]` input pins. |
| `[31:8]` | `UNUSED` | RO | Unused. Always returns `0` on read. |
* **Note:** Any write transaction (`pwrite = 1`) to `0x00` is rejected by hardware with `pslverr = 1`.

---

### `DATAOUT_REG` (Offset: `0x04`)
* **Reset Value:** `32'h0000_0000`
* **Access:** Read / Write (Byte strobe `pstrb[0]` controls bits `[7:0]`)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[7:0]` | `DATA_OUT` | R/W | **GPIO Output Value:** Directly drives the `gpio_out[7:0]` port. |
| `[31:8]` | `UNUSED` | RO | Unused. Always returns `0` on read. |

---

### `DIRECTION_REG` (Offset: `0x08`)
* **Reset Value:** `32'h0000_0000`
* **Access:** Read / Write (Byte strobe `pstrb[0]` controls bits `[7:0]`)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[7:0]` | `DIR_OE` | R/W | **GPIO Output Enable / Direction:** Directly drives `gpio_oe[7:0]`.<br>• `1'b0`: Pin configured as Input (Hi-Z / Output disabled).<br>• `1'b1`: Pin configured as Output (Output driver enabled). |
| `[31:8]` | `UNUSED` | RO | Unused. Always returns `0` on read. |

---

### `INT_EN_REG` (Offset: `0x0C`)
* **Reset Value:** `32'h0000_0000`
* **Access:** Read / Write (Byte strobe `pstrb[0]` controls bits `[7:0]`)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[7:0]` | `INT_MASK` | R/W | **Interrupt Enable Mask (Per Pin):**<br>• `1'b0`: Rising edge interrupt disabled on corresponding pin.<br>• `1'b1`: Rising edge interrupt enabled on corresponding pin. |
| `[31:8]` | `UNUSED` | RO | Unused. Always returns `0` on read. |

---

### `INT_STATUS_REG` (Offset: `0x10`)
* **Reset Value:** `32'h0000_0000`
* **Access:** Read / Write-1-to-Clear (W1C)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[7:0]` | `INT_PENDING` | W1C / RO | **Interrupt Pending Flags (Per Pin):**<br>• Set to `1` by hardware when a rising edge is detected on `gpio_in[i]` and `INT_EN_REG[i] == 1`.<br>• **W1C Operation:** Writing `1'b1` to bit `i` clears `INT_STATUS_REG[i]` to `0`. Writing `1'b0` leaves the bit state unchanged. |
| `[31:8]` | `UNUSED` | RO | Unused. Always returns `0` on read. |

---

## 5. Functional Description

### 5.1 GPIO Input/Output Mapping
* **Output Driving:** The output pins `gpio_out` continuously mirror `dataout_reg`.
* **Direction Control:** The output enable lines `gpio_oe` continuously mirror `direction_reg`.
* **Input Reading:** Reading from address `0x00` captures the instantaneous state of `gpio_in[7:0]`.

### 5.2 Edge Detection & Interrupt Logic
* **Rising Edge Detection:** The module tracks previous input states using an internal 8-bit register `prev_gpio_in`. A positive edge is detected via:
  `pos_edge_detector[i] = ~prev_gpio_in[i] & gpio_in[i]`
* **Status Latching:** When `pos_edge_detector[i]` is asserted and `int_en_reg[i] == 1`, `int_status_reg[i]` is latched to `1`.
* **Interrupt Request (`irq`):** The output signal `irq` represents a bitwise OR reduction of all pending status bits:
  `irq = |int_status_reg`
  If at least one unmasked interrupt is active, `irq` remains asserted high (`1`).

### 5.3 Write-1-to-Clear (W1C) Mechanism
* Clearing interrupt flags requires software to write `1` to the specific bit positions in `INT_STATUS_REG` (`0x10`).
* Bitwise clearing prevents race conditions where clearing one interrupt could accidentally overwrite a newly arrived interrupt on an adjacent pin.

### 5.4 APB Error Handling (`pslverr`)
* The module returns `pslverr = 1` along with `pready = 1` in the following scenarios:
  1. An attempt is made to write to the Read-Only register `DATAIN_REG` (`paddr[7:0] == 8'h00 && pwrite == 1`).
  2. Any access (read or write) targets an unmapped offset (`paddr[7:0] > 8'h10`).
* For unselected cycles (`!psel`), the module de-asserts `pready = 0`.