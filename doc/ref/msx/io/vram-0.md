
# VRAM routines (BIOS-based)

## `LDIRVM_BLOCKS`
`LDIRVM` with repetition (original routine: `COPY_BLOCK` by Eduardo A. Robsy Petrus).
- param hl: RAM source address
- param de: VRAM destination address
- param b: blocks to copy

## `UNPACK_LDIRVM`
Unpacks to VRAM using the decompression buffer
- param hl: packed data source address
- param de: VRAM destination address
- param bc: uncompressed data size

## `UNPACK_LDIRVM_CHRTBL`
Unpacks CHRTBL to the three banks
- param hl: packed CHRTBL source address

## `LDIRVM_UNPACKED_CHRTBL`
`LDIRVM` the decompresison buffer to the three CHRTBL banks

## `UNPACK_LDIRVM_CLRTBL`
Unpacks CLRTBL to the three banks
- param hl: packed CLRTBL source address

## `LDIRVM_UNPACKED_CLRTBL`
LDIRVM the decompresison buffer to the three CLRTBL banks

## `LDIRVM_UNPACKED_CHRTBL_BANK`
LDIRVM the decompresison buffer to one CHRTBL bank
- param de: VRAM destination address

## `LDIRVM_UNPACKED_CLRTBL_BANK`
LDIRVM the decompresison buffer to one CLRTBL bank
- param de: VRAM destination address

## `LDIRVM_CHRTBL`
LDIRVMs CHRTBL to the three banks
- param hl: data source address

## `LDIRVM_CLRTBL`
LDIRVMs CLRTBL to the three banks
- param hl: data source address

## `LDIRVM_CXRTBL`
LDIRVMs CHRTBL or CLRTBL to one of the banks
- param hl: data source address
- param de: VRAM destination address

## `LDIRVM_CXRTBL.KEEP_HL`
LDIRVMs CHRTBL or CLRTBL to one of the banks, but does not destroy HL
- param hl: data source address
- param de: VRAM destination address
