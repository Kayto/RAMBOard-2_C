# Parallel Collatz Demo

## Overview

A demonstration of true parallel computation between the Commodore 64 and its 1541 disk drive. Both machines contain a 6502 CPU running at ~1 MHz — this demo puts both to work simultaneously on the [Collatz conjecture](https://en.wikipedia.org/wiki/Collatz_conjecture) (also known as the 3n+1 problem).

| File | RAMBOard Required | Description |
|------|-------------------|-------------|
| `collatz_parallel.asm` | Yes (parallel mode) | Parallel + solo modes, timed results, paginated sequence viewer |

## What It Does

### The Collatz Sequence

For any positive integer N:
- If N is **even**: divide by 2
- If N is **odd**: multiply by 3 and add 1
- Repeat until N reaches 1

The **step count** is how many iterations it takes to reach 1. For example:
- N=6: 6 → 3 → 10 → 5 → 16 → 8 → 4 → 2 → 1 = **8 steps**
- N=7: takes **16 steps**
- N=2919: takes **216 steps** (hardest in range)

### Demo Flow

On startup, the user selects a mode:

#### Mode 1 — Parallel (C64 + 1541)
The workload is split by odd/even:
- **C64** computes odd numbers: 1, 3, 5, ..., 2999 (1500 numbers)
- **1541 Drive** computes even numbers: 2, 4, 6, ..., 3000 (1500 numbers)

Both CPUs run simultaneously with no synchronisation during computation. After the C64 finishes, it receives 1500 result bytes from the drive over fast serial. Requires a 1541 with RAMBOard.

#### Mode 2 — Solo (C64 Only)
The C64 computes all 3000 numbers (N=1 to 3000) by itself into a contiguous 3000-byte buffer. No drive communication occurs. Useful as a baseline comparison — the parallel mode should be roughly **2× faster**.

#### Sequence Viewer
After computation, a paginated viewer shows all 3000 results:
```
N=    1 STEPS=    0 CPU
N=    2 STEPS=    1 DRV
N=    3 STEPS=    7 CPU
N=    4 STEPS=    2 DRV
N=    5 STEPS=    5 CPU
N=    6 STEPS=    8 DRV
...
```
Each line shows which processor computed the result — **CPU** (C64) or **DRV** (1541 drive). In solo mode, all lines show **CPU**. Navigation: any key advances to the next page, **Q** or **RUN/STOP** returns to the main menu.

### Error Handling
- **No drive found**: halts with error message
- **No RAMBOard detected**: displays error, resets the drive, and returns to the menu so the user can choose solo mode instead

### Why RAMBOard Is Required for Parallel Mode

The 1541 disk drive only has **2 KB of work RAM** ($0000–$07FF). The drive code itself occupies 3 pages at $0300–$05FF (610 bytes), and the drive uses some of that RAM for its own zero page variables, stack, and buffer areas. That leaves no room to store 1500 result bytes. The RAMBOard adds **8 KB of extra RAM at $8000–$9FFF** in the drive, providing space to buffer all 1500 per-number step counts ($8000–$85DB) while the drive computes independently. Without it, the drive would have nowhere to store results and would need to send each result immediately, breaking the parallel "no synchronisation" design. In solo mode, only the C64 computes — no drive code runs, so no RAMBOard is needed.

## Memory Map

### C64

| Address | Size | Contents |
|---------|------|----------|
| `$0801` | 12 bytes | BASIC stub (`SYS 4096`) |
| `$1000`+ | ~4 KB | Main program code |
| `$A000`–`$A5DB` | 1500 bytes | Parallel: CPU results (odd N step counts) |
| `$A000`–`$ABB7` | 3000 bytes | Solo: all results (N=1..3000 contiguous) |
| `$A600`–`$ABD5` | 1500 bytes | Parallel: DRV results (even N step counts, received from drive) |

The BASIC ROM is banked out (`$01 = $36`) to make the `$A000`–`$BFFF` area available as RAM.

### 1541 Drive

| Address | Size | Contents |
|---------|------|----------|
| `$0300`–`$05FF` | 768 bytes (3 pages) | Drive code — bootstrap, command loop, Collatz routine, serial I/O |
| `$8000`–`$85DB` | 1500 bytes | RAMBOard RAM — result buffer for even N step counts |

## How It Works

### Drive Bootstrap
The C64 uploads ~610 bytes of 6502 machine code to the 1541's RAM at `$0300`–`$05FF` using standard IEC serial bus M-W (Memory-Write) commands, 32 bytes at a time. The drive code is then started with an M-E (Memory-Execute) command. After that, the drive's bootstrap receiver pulls in the full code payload over fast serial.

### Communication Protocol
The drive enters a command loop waiting for single-byte commands from the C64 via fast serial:

| Command | Action |
|---------|--------|
| `'D'` | RAMBOard detection — tests read/write at `$8000`, replies with `$01` (present) or `$00` (absent) |
| `'C'` | Collatz compute — receives start (16-bit), count (16-bit), step (8-bit); computes all step counts, stores each in RAMBOard RAM at `$8000+`; replies with 3-byte total, then bulk-sends all 1500 result bytes |
| `'Q'` | Quit — resets the drive via `JMP ($FFFC)` |

### Fast Serial
Communication uses a custom bit-banged protocol over CIA2 port A (`$DD00`) on the C64 side and VIA port B (`$1800`) on the drive side. Bytes are transferred as two nybbles using a lookup table (`tabkon` / `drv_bin2ser`) for encoding.

### Parallel Execution
After sending the `'C'` command and parameters, the C64 immediately begins its own Collatz computation. The 1541's 6502 runs independently — no handshaking or synchronisation occurs until the C64 finishes and reads back the drive's 3-byte total via `getdriv`.

### Arithmetic
Collatz intermediate values for N ≤ 3000 can exceed 65,535 (e.g., N=703 peaks at 250,504), so **24-bit working registers** are used on both CPUs. Per-number step counts fit in a single byte (maximum 216 steps in this range).

## Building

### Requirements
- [KickAssembler](http://theweb.dk/KickAssembler/) v5.25+ (Java-based 6502 assembler)
- [VICE](https://vice-emu.sourceforge.io/) emulator for testing
- Java Runtime Environment (JDK 21 or similar)

### Build Command
```
java -jar KickAss.jar demos/collatz_parallel.asm -o build/collatz_parallel.prg
```

### Running in VICE
```
x64sc -autostartprgmode 1 -drive8ram8000 -autostart build/collatz_parallel.prg
```

The `-drive8ram8000` flag enables the 8 KB RAM expansion at `$8000` in the emulated 1541, simulating the RAMBOard hardware. Solo mode works without this flag, but it is needed for parallel mode.

VS Code build tasks are also provided — see `.vscode/tasks.json`.

## Expected Results

| Mode | Approx. Jiffies (PAL) | Wall Time |
|------|----------------------|-----------|
| Solo (C64 only, 3000 numbers) | ~550–600 | ~11–12 seconds |
| Parallel (1500 numbers each) | ~280–320 | ~5.5–6.5 seconds |

The parallel mode is approximately **2× faster** than solo, demonstrating genuine dual-CPU speedup. Both 6502 processors run at ~1 MHz and execute equivalent Collatz code — the only difference is the workload split.

## Hardware

- **Commodore 64** — any model (C64, C64C, C128 in 64 mode)
- **1541 disk drive** — any revision (parallel mode only)
- **RAMBOard** — 8 KB RAM expansion board for the 1541 (parallel mode only)
- Standard IEC serial cable connecting C64 to drive

## Files

| File | Description |
|------|-------------|
| `collatz_parallel.asm` | Source — parallel + solo Collatz demo with sequence viewer |
| `README_collatz.md` | This file |

## License

Part of the RAMBOard Software project.
