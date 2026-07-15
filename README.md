# AXI4-Lite Protocol — Verilog RTL Implementation

A synthesizable Verilog implementation of an **AMBA AXI4-Lite** subsystem: one master, an interconnect (address decode + channel routing), and two slaves. Includes a self-checking testbench and full documentation diagrams.

This is the third project in a series covering the AMBA bus family, alongside [APB](../apb_project) (simple, low-power peripheral bus) and [AHB-Lite](../ahb_project) (pipelined system bus). AXI4-Lite is the most advanced of the three: a fully split-transaction protocol with five independent channels, each using its own VALID/READY handshake.

## Architecture

![AXI4-Lite Protocol Diagram](docs/axi_protocol_diagram.png)

The system is built from five modules connected inside `axi_lite_top`:

| Module | File | Description |
|---|---|---|
| `axi_lite_master` | `rtl/axi_lite_master.v` | Converts a simple `start/write/addr/wdata` request into a full AXI4-Lite transaction: AW→W→B (write) or AR→R (read) |
| `axi_lite_decoder` | `rtl/axi_lite_decoder.v` | Combinational address decoder for both AWADDR and ARADDR |
| `axi_lite_interconnect` | `rtl/axi_lite_interconnect.v` | Routes all 5 channels between master and slaves; latches which slave was addressed (`wsel`/`rsel`) so the W/B and R channels reach the correct slave even though they're temporally separated from AW/AR |
| `axi_lite_slave` | `rtl/axi_lite_slave.v` | Generic parameterized 4×32-bit register bank, zero added latency |
| `axi_lite_top` | `rtl/axi_lite_top.v` | Top-level integration of all of the above |

## The Five AXI4-Lite Channels

| Channel | Direction | Purpose |
|---|---|---|
| AW (Write Address) | Master → Slave | Address + control for a write |
| W (Write Data) | Master → Slave | Write data + byte strobes |
| B (Write Response) | Slave → Master | Write completion status |
| AR (Read Address) | Master → Slave | Address + control for a read |
| R (Read Data) | Slave → Master | Read data + status |

Every channel uses an independent VALID/READY handshake — a transfer completes only when both are asserted on the same clock edge.

## Address Map

| Region | Range | Target |
|---|---|---|
| Slave 0 | `0x0000_0000` – `0x0000_00FF` | `axi_lite_slave0` (4 registers, word-aligned) |
| Slave 1 | `0x0000_0100` – `0x0000_01FF` | `axi_lite_slave1` (4 registers, word-aligned) |

Selection is based on `ADDR[8]` (`0` → slave0, `1` → slave1), decoded independently for the write and read address channels.

## AXI4-Lite vs AHB-Lite vs APB

| | APB | AHB-Lite | AXI4-Lite |
|---|---|---|---|
| Channels | 1 (shared) | 1 (shared) | 5 (independent) |
| Handshake | PENABLE-gated | HREADY-gated | Per-channel VALID/READY |
| Address/data phases | Combined | Pipelined (separate cycles) | Fully decoupled channels |
| Typical use | Low-speed peripherals | System interconnect | High-performance interconnect |

This design supports **one outstanding transaction at a time** — a deliberate simplification. A production AXI interconnect would use `AWID`/`ARID` to track multiple in-flight transactions per master.

## Diagrams

| Diagram | File |
|---|---|
| System block / protocol diagram | [`docs/axi_protocol_diagram.png`](docs/axi_protocol_diagram.png) |
| Master FSM state diagram (write + read paths) | [`docs/axi_master_fsm.png`](docs/axi_master_fsm.png) |
| Pin diagram (`axi_lite_top`) | [`docs/axi_pin_diagram.png`](docs/axi_pin_diagram.png) |
| Master ↔ Slave interfacing diagram (all 5 channels) | [`docs/axi_interfacing_diagram.png`](docs/axi_interfacing_diagram.png) |

(Source `.svg` files are included alongside the `.png` renders for easy editing.)

## Directory Structure

```
axi_project/
├── rtl/
│   ├── axi_lite_master.v
│   ├── axi_lite_slave.v
│   ├── axi_lite_decoder.v
│   ├── axi_lite_interconnect.v
│   └── axi_lite_top.v
├── tb/
│   └── axi_lite_tb.v
├── docs/
│   ├── axi_protocol_diagram.png / .svg
│   ├── axi_master_fsm.png / .svg
│   ├── axi_pin_diagram.png / .svg
│   └── axi_interfacing_diagram.png / .svg
└── README.md
```

## `axi_lite_top` Interface

| Port | Direction | Width | Description |
|---|---|---|---|
| `ACLK` | in | 1 | System clock |
| `ARESETn` | in | 1 | Active-low asynchronous reset |
| `start` | in | 1 | Pulse to begin a transaction |
| `write` | in | 1 | `1` = write, `0` = read |
| `addr` | in | 32 | Target address |
| `wdata` | in | 32 | Write data |
| `rdata` | out | 32 | Read data, valid when `done = 1` |
| `done` | out | 1 | 1-cycle pulse on transaction completion |
| `busy` | out | 1 | High while a transaction is in progress |

## Simulation

Requires [Icarus Verilog](http://iverilog.icarus.com/):

```bash
iverilog -g2012 -o sim.out rtl/axi_lite_decoder.v rtl/axi_lite_interconnect.v rtl/axi_lite_master.v rtl/axi_lite_slave.v rtl/axi_lite_top.v tb/axi_lite_tb.v
vvp sim.out
```

Expected output:

```
ALL TESTS PASSED
```

A waveform dump (`axi_lite_tb.vcd`) is also generated for viewing in GTKWave.

> **Testbench note:** stimulus signals are driven with a `#1` delay after each `@(posedge ACLK)` rather than exactly on the edge. This avoids a classic simulation race between the testbench's blocking assignments and the DUT's own clocked logic — good practice for any synchronous testbench, and required here due to the extra combinational routing in the interconnect.

## Synthesis

All files under `rtl/` are fully synthesizable (verified with [Yosys](https://yosyshq.net/yosys/)):

```bash
yosys -p "read_verilog rtl/*.v; hierarchy -top axi_lite_top; proc; opt; synth -top axi_lite_top; stat"
```

`tb/axi_lite_tb.v` is simulation-only and is not part of the synthesizable design.

## License

MIT — see [LICENSE](LICENSE).
