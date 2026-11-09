# Memory map (v1)

| Region | Range | Size | Notes |
|--------|-------|------|-------|
| IMEM | `0x0000_0000` – `0x0000_1FFF` | 8 KiB | Word fetch; reset vector `0x0` |
| DMEM | `0x1000_0000` – `0x1000_1FFF` | 8 KiB | Byte-addressable |
| MMIO | `0x2000_0000` – … | — | LEDs, UART TX, halt/status |

Stack top (software): `0x1000_2000` via linker script (not hardwired).
