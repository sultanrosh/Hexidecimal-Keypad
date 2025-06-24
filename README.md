# 🔢 Hex Keypad Scanner (Grayhill 4x4) – Verilog Implementation

This project presents a fully elaborated Verilog design and simulation setup for interfacing with a 4x4 hexadecimal matrix keypad, such as the Grayhill 96 series. It models the digital logic behavior of a keypad scanning FSM (Finite State Machine), featuring input synchronization, keypress decoding, debouncing strategy, and comprehensive testbench validation. Designed to run on FPGA-based development platforms, the project is simulation-ready using Icarus Verilog and GTKWave.

---

## 📁 Project File Structure

* `Row_Signal.v` – Combinational module that detects the active row from key and column inputs.
* `Synchronizer.v` – Double flip-flop design that synchronizes asynchronous row signals.
* `Hex_Keypad_Grayhill_072.v` – The central FSM module that drives the column scanning, key decoding, and valid flag output.
* `Hex_Keypad_tb.v` – A robust testbench with individualized key signal declarations and diverse key press simulation cases.
* `dump.vcd` – Generated during simulation for waveform inspection using GTKWave.

---

## 🔧 Modules Breakdown and Functionality

### 🔹 `Row_Signal`

This module is purely combinational. It observes the current active column and checks the 16-bit input `Key` (representing the 4x4 keypad layout). For each row, it asserts a bit in the output `Row[3:0]` if any key in that row is pressed in conjunction with the currently active column.

> Example: If `Col[1]` is active and `Key[5]` is high (representing row 1, column 1), then `Row[1]` becomes high.

### 🔹 `Synchronizer`

Handles the conversion of potentially asynchronous row activity into a stable, clocked signal that the FSM can safely process. It uses a classic two-stage flip-flop approach:

* Stage 1 samples the result of an OR-reduction of the row signal.
* Stage 2 outputs the delayed version of stage 1 to produce the final `S_Row` signal.

This ensures metastability mitigation before FSM interaction.

### 🔹 `Hex_Keypad_Grayhill_072`

This is the main FSM which performs the following operations:

1. **Idle (S\_0):** Waits for any row activity.
2. **Scan Columns (S\_1–S\_4):** Sequentially activates each column and reads rows.
3. **Decode:** Matches the `{Row, Col}` combination to a hexadecimal key code.
4. **Hold (S\_5):** Maintains state while key is pressed to avoid repeated triggering.

It outputs:

* `Code[3:0]`: Hex code (0–F) of the detected key.
* `Valid`: Signal asserted when a legitimate keypress is detected.
* `Col[3:0]`: Actively driven column control signals.

FSM uses one-hot state encoding (`S_0` through `S_5`) to reduce decoding complexity.

### 🔹 `Hex_Keypad_tb`

A highly detailed testbench written to emulate real-world usage of the keypad. Each of the 16 keys (`K0–K15`) is independently declared to facilitate waveform debugging. It:

* Simulates single and multiple keypresses
* Emulates bouncing and rapid toggling
* Validates FSM state transitions
* Dumps data to a `.vcd` file for GTKWave analysis

---

## 🧪 Simulation & Validation Goals

* ✅ Confirm FSM transitions and logic under clean and noisy input conditions
* ✅ Validate correctness of `Code` output based on key location
* ✅ Confirm proper synchronization via `S_Row` signal
* ✅ Test debounce logic and rejection of spurious transitions
* ✅ Ensure proper FSM hold behavior under prolonged press

---

## 🚦 FSM State Definitions

| State | Binary | Purpose                                       |
| ----- | ------ | --------------------------------------------- |
| `S_0` | 000001 | Idle: Watch for activity on any row           |
| `S_1` | 000010 | Activate Col 0; check for pressed key         |
| `S_2` | 000100 | Activate Col 1; check for pressed key         |
| `S_3` | 001000 | Activate Col 2; check for pressed key         |
| `S_4` | 010000 | Activate Col 3; check for pressed key         |
| `S_5` | 100000 | Wait for key release before reactivating scan |

FSM logic uses sequential advancement and resets to `S_0` after key release.

---

## 📷 Waveform Visualization Strategy

* Each key (`K0` through `K15`) is declared separately in the testbench.
* This allows direct inspection and toggling in GTKWave.
* The `dump.vcd` file contains all signals, allowing you to monitor:

  * FSM state (`state`, `next_state`)
  * Column drivers (`Col`)
  * Key codes (`Code`)
  * Row activation (`Row`, `S_Row`)
  * Valid signal output (`Valid`)

---

## 💡 AHA Moments & Learning Reflections

These realizations emerged during implementation and debugging:

* ✅ `wire` is for real-time combinational paths; it doesn't retain state.
* ✅ `reg` is used for storage, representing sequential logic behavior.
* ✅ Double D flip-flops delay and stabilize input from mechanical buttons.
* ✅ `<=` models real-world clocked flip-flop behavior; `=` is for immediate logic updates.
* ✅ `parameter` improves readability and reuse by labeling constants.
* ✅ One-hot FSM encoding simplifies state decoding at the cost of more flip-flops.
* ✅ `$monitor` provides real-time trace of signal values on the console.
* ✅ `#` delays in testbenches allow simulation time control (not equivalent to real clock cycles).
* ✅ Continuous assignment (`assign`) can only target `wire` types, not `reg`.
* ✅ Synchronizers are critical when bridging asynchronous domains (e.g., keypad signals to FSM).
* ✅ Avoiding metastability is essential for predictable logic design.

---

## 🔍 Keypad Mapping Table (Row, Col → Hex Code)

| Row | Col | Binary (Row, Col) | Key Code |
| --- | --- | ----------------- | -------- |
| 0   | 0   | 0001\_0001        | `0x0`    |
| 0   | 1   | 0001\_0010        | `0x1`    |
| 0   | 2   | 0001\_0100        | `0x2`    |
| 0   | 3   | 0001\_1000        | `0x3`    |
| 1   | 0   | 0010\_0001        | `0x4`    |
| 1   | 1   | 0010\_0010        | `0x5`    |
| 1   | 2   | 0010\_0100        | `0x6`    |
| 1   | 3   | 0010\_1000        | `0x7`    |
| 2   | 0   | 0100\_0001        | `0x8`    |
| 2   | 1   | 0100\_0010        | `0x9`    |
| 2   | 2   | 0100\_0100        | `0xA`    |
| 2   | 3   | 0100\_1000        | `0xB`    |
| 3   | 0   | 1000\_0001        | `0xC`    |
| 3   | 1   | 1000\_0010        | `0xD`    |
| 3   | 2   | 1000\_0100        | `0xE`    |
| 3   | 3   | 1000\_1000        | `0xF`    |

---

## 🔬 Technical Summary

This Verilog design showcases practical digital design techniques:

* FSM state machine logic using one-hot encoding
* Synchronization of mechanical button signals
* Clean combinational vs sequential separation
* Modular design with clear interface boundaries
* Waveform inspection via GTKWave to validate function

It emulates real-world embedded keypad behavior as used in calculators, access panels, vending machines, and industrial control pads.

---

## 📦 How to Build & Run Simulation

### 📌 Prerequisites

Install [Icarus Verilog](http://iverilog.icarus.com/) and [GTKWave](http://gtkwave.sourceforge.net/).

### ▶️ Simulation Steps

```bash
# Compile all modules and the testbench
iverilog -o hex_keypad.vvp Hex_Keypad_tb.v Row_Signal.v Synchronizer.v Hex_Keypad_Grayhill_072.v

# Run the simulation
vvp hex_keypad.vvp

# View waveform
gtkwave dump.vcd
```

---

## 👤 Author
**Kourosh Rashidiyan**
🗓️ June 2025
