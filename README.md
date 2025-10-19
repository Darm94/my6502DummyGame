# NES-Style Pixel Movement in 6502 Assembly

A small educational exercise in MOS 6502 Assembly that move a “pixel” (a memory cell) using the joypad.

Includes: Up/Down/Left/Right movement, press detection (one move per press), and a horizontal Pac-Man effect (wrap on the same row).

---

## General Structure

| Section | Description |
|----------|-------------|
| `.ORG $8000` | program starting point |
| `start:` | initializes registers and lights up the first pixel |
| `loop:` | main loop: reads the joypad and decides whether to move |
| `chk_up/down/left/right:` | check each direction |
| `nmi`, `break` | empty interrupt routines |
| vectors at `$FFFA` | NMI / RESET / IRQ addresses |

---

## Movement Logic

- **X**: current pixel position (offset inside page `$0200`)  
- **Y**: edge detection flag  
  - `0`: no key pressed, allow movement  
  - `1`: key already pressed, block until release  
- **$4000**: byte containing button states  
  - bit0 = Up  
  - bit1 = Down  
  - bit2 = Left  
  - bit3 = Right  

Each time you press a button:
1. turns off the pixel at the current position  
2. updates X (increments/decrements by 1 or by 16)  
3. lights up the pixel at the new position  
4. sets `Y=1` to block repeated input until release  

---

## 6502 Instructions Used

| Instruction | Meaning | Example Use |
|--------------|----------|-------------|
| `LDA` | Load Accumulator | loads a value into A |
| `STA` | Store Accumulator | stores A into memory |
| `AND` | Logical AND (bitmask) | `AND #%00000010` isolates the Down bit |
| `BEQ` / `BNE` | branch if Zero=1 / Zero=0 | used after AND or CPY |
| `CPY` | compare Y with value | used to check the press flag |
| `INX` / `DEX` | increment/decrement X | horizontal movement |
| `TXA` / `TAX` | transfer X↔A | needed for arithmetic operations on X |
| `CLC` / `SEC` | clear/set carry | prepares ADC or SBC |
| `ADC` / `SBC` | add/subtract with carry | vertical movement (±16) |
| `RTI` | return from interrupt | empty routines for NMI/IRQ |

---

## Horizontal Pac-Man Effect

When X exceeds the 16th column (or goes below 0):

- Right: if `(X & $0F) == 0` then `X = X - 16`
- Left:  if `(X & $0F) == 15` then `X = X + 16`

This keeps the pixel on the same row, simulating horizontal wrap-around.
Vertically the pixel automatically restarts from the opposite side in the same column

---
## Sources

- [NesDev Wiki – 6502 CPU Architecture](https://www.nesdev.org/wiki/CPU)
- [MOS 6502 Instruction Set Reference](https://www.masswerk.at/6502/6502_instruction_set.html)
- [PyNecroassembler Project](https://pypi.org/project/necroassembler/)
- [Programming the 6502 – Easy 8-bit Assembly Guide](https://skilldrick.github.io/easy6502/)

--------------------------------------------------------------
   Behavior Summary
   ----------------

   Start:               first pixel at $0200  
   Press a key:         move by 1 bit (Left/Right) or 16 bit (Up/Down)  
   Release:             allows movement again  
   Horizontal and vertical edges:    pixel reappears on the opposite side of the same row and the same for the vertical edges in the same column

   Compilation (necroassembler):  
   python -m necroassembler.cpu.mos6502 main.asm main.bin

   Tested on : Dummy 6502


Purely educational project to understand the registers, logical operations, and vector handling of the MOS 6502 processor.
