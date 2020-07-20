# Generic Z80 assembly convenience routines

## `ADD_HL_A`

Emulates the instruction `add hl, a` (or `hl += a` in C syntax)
- param hl: operand
- param a: usigned operand

## `ADD_HL_A_A`

Emulates the instruction `hl += 2*a` (in C syntax)
- param hl: operand
- param a: usigned operand

## `GET_HL_A_BYTE`

Reads a byte from a byte array (i.e.: `a = hl[a]` in C syntax)
- param hl: byte array address
- param a: usigned 0-based index
- ret hl: pointer to the byte (i.e.: hl + a)
- ret a: read byte

## `GET_HL_A_WORD`
Reads a word from a word array (i.e.: `h,l = hl[a+1], hl[a]` in C syntax)
- param hl: word array address
- param a: unsigned 0-based index (0, 2, 4...)
- ret hl: read word

## `LD_HL_HL`
Emulates the instruction `ld hl, [hl]`
- param hl: address
- ret hl: read word

## `JP_HL`
Simply `jp [hl]`, but can be used to emulate the instructions `call [hl]`, `jp <condition>, [hl]`, and `call <condition>, [hl]`
- param hl: address

## `JP_HL_INDIRECT`
Emulates the instruction `jp [[hl]]` or `call [[hl]]`
- param hl: pointer to the address
- touches a

## `JP_TABLE`
Uses a jump table.
- param hl: jump table address
- param a: unsigned 0-based index (0, 1, 2...)

Usage: both `call JP_TABLE` and `jp JP_TABLE` are valid

## `JP_TABLE_2`
Uses a jump table (with pre-doubled indexes)
- param hl: jump table address
- param a: unsigned 0-based index (0, 2, 4...)

## `ADD_ARRAY_IX:`
Adds an element to an array and returns the address of the added element
- param ix: array.count address (byte size)
- param c: size of each array element
- ret ix: address of the new element

## `GET_ARRAY_IX`
Locates an element into an array
- param ix: array address (skipped the size byte)
- param c: size of each array element
- param a: 0-based index (0, 1, 2...)
- ret ix: address of the element

## `FOR_EACH_ARRAY_IX`
Executes a routine for every element of an array
- param ix: array.count address (byte size)
- param c: size of each array element
- param hl: routine to execute on every element, that will receive the address of the element in ix

## `RET_ZERO`
Convenience routine to return 0 and the z flag.

Intended to be used within conditionals only (i.e.: `jp <condition>, RET_ZERO`); inline otherwise.
- ret a: 0
- ret z

## `RET_NOT_ZERO`
Convenience routine to return -1 ($ff) and the nz flag.
- ret a: -1 ($ff)
- ret nz
