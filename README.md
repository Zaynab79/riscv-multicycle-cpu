# RISC-V Multicycle CPU

A synthesizable multicycle RV32I processor written in Verilog/SystemVerilog — built up from a
hand-written ALU into a full CPU with CSR-based interrupts and memory-mapped peripherals for the
Gecko5 educational FPGA board.

## Architecture

The processor executes one instruction every 4–5 clock cycles, moving through a
`FETCH1 → FETCH2 → DECODE → <execute>` state machine with a dedicated execute path per
instruction format (U/I/S/B/J-type, `JALR`, loads split across two cycles, and `BREAK` to halt).

| Module | Role |
|---|---|
| `register_file.v` | 32×32-bit register file, `x0` hardwired to 0, asynchronous read / synchronous write |
| `pc.v`, `ir.v` | Program counter and instruction register |
| `decoder.v` | Instruction field / immediate decoding |
| `controller.v` | The multicycle FSM described above; generates all datapath control signals |
| `alu.v` | 32-bit ALU, dispatching to 4 functional units via a 6-bit opcode |
| `add_sub.v`, `comparator.v`, `logic_unit.v`, `shift_unit.v`, `mux4x32.v`, `mux2x32.v` | The ALU's internal add/subtract, signed & unsigned comparison, bitwise logic, and shift (SLL/SRL/SRA) units |
| `csr.v` | `mstatus`, `mie`, `mtvec`, `mepc`, `mcause`, `mip` — enough of Zicsr to take traps/interrupts and `mret` |
| `cpu.sv` | Top-level core: wires the datapath, controller and CSR block together |
| `mem.sv` | Single-port instruction/data memory |
| `buttons.v`, `leds.v`, `seven_seg_lcd.v` | Memory-mapped peripherals: buttons/joystick/DIP switches, an RGB LED matrix, and four 7-segment displays |
| `gecko.v` (module `tb`) | SoC top level: instantiates `cpu`, `mem` and the peripherals and routes the address bus between them — this is what Verilator simulates |

## Repository layout

```
verilog/
├── *.v, *.sv          RTL sources (see table above)
├── Makefile           Verilator build/sim flow + RISC-V toolchain assembly build
├── mmio.ld            Linker script (code starts at 0x8000_0000, matching the CPU's reset PC)
├── program.s          Example bare-metal program (interrupt-driven button/LED demo)
├── flags.txt          Verible lint rule configuration
├── testbench/         Standalone unit testbenches for the ALU sub-modules
└── dump/              Verilator waveform (.vcd) output — generated, not tracked
```

## Building & simulating

Requirements: [Verilator](https://www.veripool.org/verilator/), [GTKWave](https://gtkwave.sourceforge.net/),
and a `riscv32` GNU toolchain (set `RVTOOLPREFIX` at the top of `Makefile` if yours isn't
`riscv64-unknown-linux-gnu-`).

```bash
cd verilog
make build_program      # assembles program.s and builds the full SoC simulation
./Vtb                   # run the simulation
gtkwave dump/tb.vcd     # inspect the waveform
```

To simulate just the ALU (or one of its sub-units) against its testbench:

```bash
verilator --binary --trace -Wno-fatal --top-module tb_alu -o Vtb_alu testbench/tb_alu.v *.v
./obj_dir/Vtb_alu
gtkwave dump/tb_alu.vcd
```

Lint the RTL with [Verible](https://github.com/chipsalliance/verible):

```bash
verible-verilog-lint --rules_config=flags.txt *.v *.sv
```

## ISA support

The RV32I base integer instruction set, plus the subset of Zicsr needed for exceptions and
interrupts (`csrrw`/`csrrs`/`csrrc`, `mret`, and the `mstatus`/`mie`/`mtvec`/`mepc`/`mcause`/`mip`
CSR bank).

## Related project

[`game-of-life-riscv`](../../game-of-life-riscv) — Conway's Game of Life written entirely in
RISC-V assembly for this CPU, driving the LED matrix and reading the on-board buttons through the
memory-mapped I/O this SoC exposes.

## Origin

Built across a sequence of computer architecture labs: starting from a standalone combinational
ALU, then growing it into a complete multicycle processor with a CSR/interrupt subsystem and
memory-mapped I/O for the Gecko5 board.
