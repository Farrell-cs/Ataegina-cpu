High level overview of what the whole CPU/Core will look like (hopefully):
![[Pasted image 20261021202412.png]]
Can be seen from "Computer Organization and Design: The Hardware/Software Interface"

**Flow:**
1. The instruction is fetched, and the PC is incremented.
2. Two registers, x2 and x3, are read from the register file; also, the main control unit computes the setting of the control lines during this step.
3. The ALU operates on the data read from the register file, using portions of the opcode to generate the ALU function.
4. The result from the ALU is written into the destination register (x1) in the register file.
## Program Counter
A program counter is essentially a buffer which contains the address of the next instruction that'll be executed from the memory and will act as a guide for the whole CPU itself ig. When it finishes fetching an instruction from the memory, it'll increment 1 so it's ready to fetch another instruction from the memory.

Reference:
- https://www.geeksforgeeks.org/operating-systems/what-is-program-counter/

## Decoder
