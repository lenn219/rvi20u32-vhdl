# Memory map (v1)

| Region | Range | Size | Notes |
|--------|-------|------|-------|
| IMEM | `0x0000_0000` – `0x0000_1FFF` | 8 KiB | Word fetch; reset vector `0x0` |
| DMEM | `0x1000_0000` – `0x1000_1FFF` | 8 KiB | Byte-addressable |
| MMIO | `0x2000_0000` – … | — | LEDs, UART TX, halt/status |

## MMIO detail

| Address | Name | Access | Description |
|---------|------|--------|-------------|
| `0x2000_0000` | LED | R/W | Low 8 bits drive `leds[7:0]` |
| `0x2000_0004` | UART TX DATA | W | Write low byte starts an **8N1** frame when ready |
| `0x2000_0008` | UART STATUS | R | bit0=`ready`, bit1=`busy` |
| `0x2000_000C` | STATUS | R | bit0=`halted`, bit1=`halt_ill` |

UART baud: `CLKS_PER_BIT` (default **434** ≈ 50 MHz / 115200). Idle line high. Software should poll `ready` before each write.

Stack top (software): `0x1000_2000` via linker script (not hardwired).
