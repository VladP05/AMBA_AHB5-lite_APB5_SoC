# APB 32-bit Counter Specification (`peripheral_slave1`)

## 1. Overview
The `peripheral_slave1` module is a 32-bit programmable counter compatible with the AMBA APB bus. It utilizes a synchronous clock-enable prescaler to remain in the same clock domain as the bus and supports both **One-Shot** and **Periodic** operating modes.

---

## 2. Interface Signals

| Signal | Dir | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | `clk` | System clock |
| `rst_n` | Input | 1 | Async | Active-low asynchronous reset |
| `paddr` | Input | 32 | `clk` | APB address bus |
| `pprot` | Input | 3 | `clk` | APB protection type |
| `psel` | Input | 1 | `clk` | APB select signal |
| `penable` | Input | 1 | `clk` | APB enable |
| `pwrite` | Input | 1 | `clk` | 1 = Write transaction, 0 = Read transaction |
| `pwdata` | Input | 32 | `clk` | APB write data bus |
| `pstrb` | Input | 4 | `clk` | APB byte-lane write strobes |
| `pready` | Output | 1 | `clk` | APB slave ready signal |
| `prdata` | Output | 32 | `clk` | APB read data bus |
| `pslverr` | Output | 1 | `clk` | APB slave error response |

---

## 3. Register Map

| Offset | Register | Access | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x00` | **`CTRL_REG`** | R/W | `0x00000000` | Control register (Enable, Mode) |
| `0x04` | **`STATUS_REG`** | R/W | `0x00000000` | Status and timeout flag |
| `0x08` | **`LOAD_REG`** | R/W | `0x00000000` | Target counter reload value |
| `0x0C` | **`VALUE_REG`** | RO | `0x00000000` | Current counter value (Write triggers `pslverr`) |
| `0x10` | **`PRESCALER_REG`**| R/W | `0x00000000` | Clock prescaler division limit |

---

## 4. Register Descriptions

### `CTRL_REG` (Offset: `0x00`)
* **Reset Value:** `0x00000000`
* **Access:** Read / Write (lower 8 bits `[7:0]` only via `pstrb[0]`)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[0]` | `EN` | R/W | **Counter Enable:**<br>• `1'b0`: Module disabled (internal prescaler held at `0`).<br>• `1'b1`: Module enabled (prescaler starts counting). |
| `[1]` | `MODE` | R/W | **Operation Mode:**<br>• `1'b0` (One-Shot): Upon reaching the target value, `VALUE_REG` resets to `0` and hardware automatically clears `EN` to `0`.<br>• `1'b1` (Periodic): Upon reaching the target value, `VALUE_REG` resets to `0` and counting continues. |
| `[7:2]` | `RESERVED` | R/W | Reserved bits on byte 0. |
| `[31:8]` | `UNUSED` | RO | Unused. Always returns `0` on read. |

---

### `STATUS_REG` (Offset: `0x04`)
* **Reset Value:** `0x00000000`
* **Access:** Read / Write (lower 8 bits `[7:0]` only via `pstrb[0]`)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[0]` | `TIMEOUT` | R/W | **Target Match Flag:**<br>• `1'b1`: Set by hardware when `VALUE_REG == LOAD_REG` during an active `tick`.<br>• Cleared by software writing `1'b0`. |
| `[7:1]` | `RESERVED` | R/W | Reserved bits on byte 0. |
| `[31:8]` | `UNUSED` | RO | Unused. Always returns `0` on read. |

---

### `LOAD_REG` (Offset: `0x08`)
* **Reset Value:** `0x00000000`
* **Access:** Read / Write (supports byte-lane writes via `pstrb[3:0]`)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[31:0]` | `LOAD_VAL` | R/W | **Target Value:** Number of `tick` pulses required to assert the timeout flag. |

---

### `VALUE_REG` (Offset: `0x0C`)
* **Reset Value:** `0x00000000`
* **Access:** Read-Only (RO)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[31:0]` | `CURRENT_VAL` | RO | **Current Counter Value:** Reflects the real-time status of the counter. Increments by `+1` on every `tick`.<br>**Note:** Any write attempt (`pwrite = 1`) is rejected with `pslverr = 1`. |

---

### `PRESCALER_REG` (Offset: `0x10`)
* **Reset Value:** `0x00000000`
* **Access:** Read / Write (supports byte-lane writes via `pstrb[3:0]`)

| Bits | Field Name | Access | Description |
| :--- | :--- | :---: | :--- |
| `[31:0]` | `PRESCALER_VAL` | R/W | **Prescaler Limit:** Generates a 1-cycle active internal `tick` pulse every `(PRESCALER_VAL + 1)` cycles of `clk`. |

---

## 5. Functional Description

1. **Prescaler & Tick Generation:**
   * When `CTRL_REG[0] == 1`, the internal counter increments on each positive edge of `clk`.
   * When the counter matches the value in `PRESCALER_REG`, the internal `tick` signal transitions to `1` for one cycle and the counter resets to `0`.

2. **Counting and Operating Modes:**
   * On every active `tick`, `VALUE_REG` increments if `VALUE_REG != LOAD_REG`.
   * When `VALUE_REG == LOAD_REG`:
     * `STATUS_REG[0]` transitions to `1`.
     * In **Periodic Mode** (`CTRL_REG[1] == 1`), `VALUE_REG` resets to `0` and resumes counting on the next tick.
     * In **One-Shot Mode** (`CTRL_REG[1] == 0`), `VALUE_REG` resets to `0` and `CTRL_REG[0]` is automatically cleared to `0`.

3. **APB Error Handling (`pslverr`):**
   * The module asserts `pslverr = 1` along with `pready = 1` under two conditions:
     1. An attempt is made to write to the Read-Only register `VALUE_REG` (`paddr[7:0] == 8'h0C && pwrite == 1`).
     2. Any access (read or write) targets an unmapped address space (`paddr[7:0] > 8'h10`).