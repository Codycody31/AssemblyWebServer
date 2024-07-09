# Instructions

## MOV

- `MOV` copies data from one location to another.
- Syntax: `MOV destination, source`
- Example: `MOV AL, 0x0A` (Move 0x0A to AL)
- Example: `MOV AX, BX` (Move BX to AX)
- Example: `MOV [0x1234], AL` (Move AL to memory location 0x1234)

## ADD

- `ADD` adds two numbers.
- Syntax: `ADD destination, source`
- Example: `ADD AL, 0x0A` (Add 0x0A to AL)
- Example: `ADD AX, BX` (Add BX to AX)
- Example: `ADD [0x1234], AL` (Add AL to memory location 0x1234)

## SUB

- `SUB` subtracts two numbers.
- Syntax: `SUB destination, source`
- Example: `SUB AL, 0x0A` (Subtract 0x0A from AL)
- Example: `SUB AX, BX` (Subtract BX from AX)
- Example: `SUB [0x1234], AL` (Subtract AL from memory location 0x1234)

## SYSCALL

- `SYSCALL` is used to make a system call.
- Syntax: `SYSCALL`
- Example: `SYSCALL` (Make a system call)

## POP

- `POP` removes the top value from the stack.
- Syntax: `POP destination`
- Example: `POP AX` (Pop the top value from the stack to AX)

## CALL

- `CALL` calls a subroutine.
- Syntax: `CALL subroutine`
- Example: `CALL 0x1234` (Call the subroutine at memory location 0x1234)
- Example: `CALL string_to_int` (Call the subroutine named string_to_int)
