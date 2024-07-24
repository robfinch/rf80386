# rf8088/rf80386
Updating this project to be part of the Bigfoot project.

# Differences from a 8088/80386
The bus interface is completely different. The rf8088/rf80386 is using the FTA bus for data access and assumes an instruction cache is present for instruction access.
The instruction cache interface expects to be supplied the address and returns a 16-byte bundle of instructions located at the address.
The interrupt acknowledge cycle just reads a single byte using one memory access rather than performing two accesses and ignoring the first.
The ENTER instruction is not fully supported. Only nesting levels 0 and 1 are supported.
The reset address is changed to the last 64k page of memory: $FFFF0000. This is to avoid issues with the cache controller reading past the end of memory.

# Status
The 8088 was close to working back in 2013. It was able to run small test programs. The update may have introduced new bugs.
The 80386 is not yet completely coded.

