This'll 
## General Idea or Layout
![[Pasted image 20261020225100.png]]

![[Pasted image 20261020225108.png]]

![[Pasted image 20261021161544.png]]

Messages:
Okay guys, after having some thought kurang lebih kaya gini deh high level overviewnya:

Kita basically ngebuat architecture yang kita udh pelajarin di OAK dan AKM, tapi hal tsb itu designed to be run on CISC (beda dengan RISC V), that's why kita modifikasi sedikit pipelinenya biar sesuai.

Essentially kita kurleb ada kita layer (from lowest to highest):

Layer 1 (Datapth/Component):
- ALU
- Registers
- Instruction Decoder
- Instruction buffer
- Branch Predictor
- Memory Controller (and all the components necessary to make one)
Layer 2 (Pipeline):
- Fetch ('PC + 4' to get the next instruction on memory)
- Decode (Reads opcode and data, or "unpacking the 32 bit input")
- Register read (Do register stuff, we have 32 registers btw)
- Execute (ALU computes the mathematical result, or calculates memory addresses for loads/stores, or evaluates branch targets.)
- Memory Access (LW/SW to memory)
- Writeback (Outputs and sends final result into target register)
Layer 3 (SoC):
* Clock
* Main Memory
* Peripehrals
