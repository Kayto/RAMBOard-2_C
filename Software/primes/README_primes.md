# Parallel Prime Sieve Demo

## Overview

A demonstration of true parallel computation between the Commodore 64 and its 1541 disk drive. Both machines contain a 6502 CPU running at ~1 MHz — this demo puts both to work simultaneously on [primality testing](https://en.wikipedia.org/wiki/Primality_test) by trial division across the range N=1 to 3000.

| File | RAMBOard Required | Description |
|------|-------------------|-------------|
| `primes_sieve_parallel.asm` | Yes (parallel mode) | Parallel + solo modes, timed results, paginated result viewer |

## What It Does

### Primality by Trial Division

For each number N in the range 1–3000, the test is:
- N=1 is **not prime**
- N=2 is **prime** (only even prime)
- If N is **even** and N > 2: **not prime**
- Otherwise, divide N by each odd number 3, 5, 7, ..., up to √N
- If any divisor divides N evenly: **not prime**
- If no divisor works: **prime**

Since √3000 ≈ 54.7, the maximum trial divisor needed is **55**. The result for each number is a single byte: `1` = prime, `0` = not prime.

### Demo Flow

On startup, the user selects a mode:

#### Mode 1 — Parallel (C64 + 1541)
The workload is split by range:
- **C64** tests N = 1, 2, 3, ..., 1500 (first half)
- **1541 Drive** tests N = 1501, 1502, ..., 3000 (second half)

Both CPUs run simultaneously with no synchronisation during computation. After the C64 finishes, it receives 1500 result bytes from the drive over fast serial. Requires a 1541 with RAMBOard.

#### Mode 2 — Solo (C64 Only)
The C64 tests all 3000 numbers (N=1 to 3000) by itself into a contiguous 3000-byte buffer. No drive communication occurs. Useful as a baseline comparison — the parallel mode should be roughly **2× faster**.

#### Result Viewer
After computation, a paginated viewer shows all 3000 results:
```
N=    1   -   CPU
N=    2 PRIME CPU
N=    3 PRIME CPU
N=    4   -   CPU
N=    5 PRIME CPU
N=    6   -   CPU
N=    7 PRIME CPU
...
N= 1501 PRIME DRV
N= 1502   -   DRV
N= 1503   -   DRV
```
Each line shows **PRIME** or **-** (not prime), and which processor computed the result — **CPU** (C64) or **DRV** (1541 drive). In solo mode, all lines show **CPU**. Navigation: any key advances to the next page, **Q** or **RUN/STOP** returns to the main menu.

### Error Handling
- **No drive found**: halts with error message
- **No RAMBOard detected**: displays error, resets the drive, and returns to the menu so the user can choose solo mode instead

### Why RAMBOard Is Required for Parallel Mode

The 1541 disk drive only has **2 KB of work RAM** ($0000–$07FF). The drive code itself occupies 3 pages at $0300–$05FF (~606 bytes), and the drive uses some of that RAM for its own zero page variables, stack, and buffer areas. That leaves no room to store 1500 result bytes. The RAMBOard adds **8 KB of extra RAM at $8000–$9FFF** in the drive, providing space to buffer all 1500 primality results ($8000–$85DB) while the drive computes independently. Without it, the drive would have nowhere to store results and would need to send each result immediately, breaking the parallel "no synchronisation" design. In solo mode, only the C64 computes — no drive code runs, so no RAMBOard is needed.

## Memory Map

### C64

| Address | Size | Contents |
|---------|------|----------|
| `$0801` | 12 bytes | BASIC stub (`SYS 4096`) |
| `$1000`+ | ~4 KB | Main program code |
| `$A000`–`$A5DB` | 1500 bytes | Parallel: CPU results (N=1..1500) |
| `$A000`–`$ABB7` | 3000 bytes | Solo: all results (N=1..3000 contiguous) |
| `$A600`–`$ABDB` | 1500 bytes | Parallel: DRV results (N=1501..3000, received from drive) |

The BASIC ROM is banked out (`$01 = $36`) to make the `$A000`–`$BFFF` area available as RAM.

### 1541 Drive

| Address | Size | Contents |
|---------|------|----------|
| `$0300`–`$05FF` | 768 bytes (3 pages) | Drive code — bootstrap, command loop, primality test, serial I/O |
| `$8000`–`$85DB` | 1500 bytes | RAMBOard RAM — result buffer for N=1501..3000 |

## How It Works

### Drive Bootstrap
The C64 uploads ~606 bytes of 6502 machine code to the 1541's RAM at `$0300`–`$05FF` using standard IEC serial bus M-W (Memory-Write) commands, 32 bytes at a time. The drive code is then started with an M-E (Memory-Execute) command. After that, the drive's bootstrap receiver pulls in the full code payload over fast serial.

### Communication Protocol
The drive enters a command loop waiting for single-byte commands from the C64 via fast serial:

| Command | Action |
|---------|--------|
| `'D'` | RAMBOard detection — tests read/write at `$8000`, replies with `$01` (present) or `$00` (absent) |
| `'P'` | Prime sieve — receives start (16-bit), count (16-bit); tests each N for primality, stores results in RAMBOard RAM at `$8000+`; replies with 2-byte prime count, then bulk-sends all 1500 result bytes |
| `'Q'` | Quit — resets the drive via `JMP ($FFFC)` |

### Fast Serial
Communication uses a custom bit-banged protocol over CIA2 port A (`$DD00`) on the C64 side and VIA port B (`$1800`) on the drive side. Bytes are transferred as two nybbles using a lookup table (`tabkon` / `drv_bin2ser`) for encoding.

### Parallel Execution
After sending the `'P'` command and parameters, the C64 immediately begins its own primality testing. The 1541's 6502 runs independently — no handshaking or synchronisation occurs until the C64 finishes and reads back the drive's 2-byte prime count via `getdriv`.

### Arithmetic
Trial division uses a 16-bit dividend (the number N) divided by an 8-bit divisor (3, 5, 7, ..., 55) via a shift-and-subtract algorithm that produces the remainder. The test value is preserved across each trial division call using the stack, since the mod routine is destructive. Each result is a single byte (1 or 0).

## Building

### Requirements
- [KickAssembler](http://theweb.dk/KickAssembler/) v5.25+ (Java-based 6502 assembler)
- [VICE](https://vice-emu.sourceforge.io/) emulator for testing
- Java Runtime Environment (JDK 21 or similar)

### Build Command
```
java -jar KickAss.jar demos/primes_sieve_parallel.asm -o build/primes_sieve_parallel.prg
```

### Running in VICE
```
x64sc -autostartprgmode 1 -drive8ram8000 -autostart build/primes_sieve_parallel.prg
```

The `-drive8ram8000` flag enables the 8 KB RAM expansion at `$8000` in the emulated 1541, simulating the RAMBOard hardware. Solo mode works without this flag, but it is needed for parallel mode.

VS Code build tasks are also provided — see `.vscode/tasks.json`.

## Expected Results

There are **431 primes** in the range 1–3000 (from 2 to 2999).

| Mode | Approx. Jiffies (PAL) | Notes |
|------|----------------------|-------|
| Solo (C64 only, 3000 numbers) | ~500–600 | All computation on C64 |
| Parallel (1500 numbers each) | ~250–350 | Both CPUs working simultaneously |

The parallel mode is approximately **2× faster** than solo, demonstrating genuine dual-CPU speedup. Both 6502 processors run at ~1 MHz and execute equivalent trial-division code — the only difference is the range split.

## Hardware

- **Commodore 64** — any model (C64, C64C, C128 in 64 mode)
- **1541 disk drive** — any revision (parallel mode only)
- **RAMBOard** — 8 KB RAM expansion board for the 1541 (parallel mode only)
- Standard IEC serial cable connecting C64 to drive

## Files

| File | Description |
|------|-------------|
| `primes_sieve_parallel.asm` | Source — parallel + solo prime sieve with result viewer |
| `README_primes.md` | This file |

## License

Part of the RAMBOard Software project.
