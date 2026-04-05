<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

**RAM**: only 8x32 bit data available, but this RAM designed 8x40 for ECC implement  
  
**MBIST (Memory Built-In Self-Test)**: using March algorithm. In this project, I decided using March C-:  
1. ↑ (w0)  
2. ↑ (r0,w1)  
3. ↑ (r1,w0)  
4. ↓ (r0,w1)  
5. ↓ (r1,w0)  
6. ↓ (r0)  
  
**Hamming ECC (Hamming Error Correcting Code)** SECDED:  
We add r parity bits such that: 2^r = m+r+1   
	where:   
	m = number of data bits  
	r = number of parity bits  
Parity bits are placed at power-of-two positions  
Each parity bit monitors a specific subset of bits:
- P1 checks all bits with LSB = 1: 1,3,5,7,…
- P2 checks bits with second LSB = 1: 2,3,6,7,…
- P4 checks bits with third LSB = 1: 4,5,6,7,12,13,…
- … and so on.  
When reading data, parity bits are recalculated and compared with the stored parity bits.  	
## How to test

ECC and MBIST test are the same, they have 2 parts:  
- Functional Check: Check if normal function of DUT is working
- Fault injection: simulation error to watch behaviors of DUT  
  
All test have checker

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
