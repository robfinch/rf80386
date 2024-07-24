#
PATH = $PATH;C:\F\f\cores2024\rf8088\software\CC64\cc64\cc64\debug;"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.28.29333\bin\Hostx64\x64\bin\Hostx64\x64\"
INC = C:\F\f\cores2024\rf8088\software\source\;C:\F\F\cores2024\rf8088\software\Femtiki\source\kernel\;C:\F\f\cores2024\rf8088\software\inc\
INCLUDE = C:\F\f\cores2024\rf8088\software\source\;C:\F\F\cores2024\rf8088\software\Femtiki\source\kernel\;C:\F\f\cores2024\rf8088\software\inc\
FPPINC  = C:\F\f\cores2024\rf8088\software\source\;C:\F\F\cores2024\rf8088\software\Femtiki\source\kernel\;C:\F\f\cores2024\rf8088\software\inc\
CXX = arpl
#CXX = opt
CFLAGS2 = -c99 -IC:\F\f\cores2024\rf8088\software\inc\ -O=31
#CFLAGS = -w -S -fno-exceptions
CFLAGS = -w -S -fno-exceptions -a21 -finline0


#

TEST:
	del t386.bin
	vasmx86_std_win32.exe -Fvobj -Lbpl=5 -L t386.lst -mi386 t386.asm -o t386.o
	vlink -M -T t386.cmd -brawbin1 t386.o -o rom.bin
	bin2ver rom.bin -b128 m -mod65536
	bin2ver rom.bin -b128 -mod65536

BIOS:
	del boot_rom.bin
	del boot_rom.lst
	arpl $(CFLAGS) bootrom.a
	arpl $(CFLAGS) Fibonacci.a
	arpl_riscv $(CFLAGS) Fibonacci.a
	arpl $(CFLAGS) serial.a
	arpl $(CFLAGS) xmodem.a
	arpl $(CFLAGS) SIEVE.a
	arpl $(CFLAGS) printf_again.c
#	arpl $(CFLAGS) os_stub.c

	vasmQupls_std_win32.exe -Fvobj -Lbpl=5 -L bootrom.lst bootrom.asm -o bootrom.o
	vasmQupls_std_win32.exe -Fvobj -Lbpl=5 -L serial.lst serial.asm -o serial.o
	vasmQupls_std_win32.exe -Fvobj -Lbpl=5 -L xmodem.lst xmodem.asm -o xmodem.o
	vasmQupls_std_win32.exe -Fvobj -L boot.lst boot.asm -o boot.o
	vasmQupls_std_win32.exe -Fvobj -L reset_vector.lst reset_vector.asm -o reset_vector.o
	vasmQupls_std_win32.exe -Fvobj -L ramtest.lst ramtest.asm -o ramtest.o
	vasmQupls_std_win32.exe -Fvobj -L fibonacci.lst fibonacci.asm -o fibonacci.o
	vasmQupls_std_win32.exe -Fvobj -Lbpl=5 -L sieve.lst sieve.asm -o sieve.o
	vasmQupls_std_win32.exe -Fvobj -Lbpl=5 -L printf_again.lst printf_again.asm -o printf_again.o
	vasmQupls_std_win32.exe -Fvobj -Lbpl=5 -L ..\cc64rt\source\cc64rt.lst ..\cc64rt\source\cc64rt.asm -o cc64rt.o
	vasmQupls_std_win32.exe -Fvobj -Lbpl=5 -L ..\cc64rt\source\__store.lst ..\cc64rt\source\__store.asm -o __store.o
	vasmQupls_std_win32.exe -Fvobj -Lbpl=5 -L ..\cc64rt\source\__load.lst ..\cc64rt\source\__load.asm -o __load.o
#	vasmQupls_std_win32.exe -Fvobj -L LEDTest.lst LEDTest.asm -o LEDTest.o
#	vasmrf68000_mot_win32.exe -Fvobj -L cputest.lst cputest.asm -o cputest.o
#	vasmrf68000_mot_win32.exe -Fvobj -L boot.lst boot.asm -o boot.o -m68010
#	vasmm68k_std_win32.exe -Fvobj -L boot.lst boot.asm -o boot.o -m68010
#	vasmrfPhoenix_std_win32.exe -Fvobj -L add.lst add.asm -o add.o
	vlink -M -T rom_bios.cmd -brawbin1 boot.o cc64rt.o __store.o __load.o reset_vector.o -o boot.bin
	vlink -T ramtest.cmd -brawbin1 ramtest.o -o ramtest.bin
	vlink -T rom_bios.cmd -brawbin1 fibonacci.o -o fibonacci.bin
#	vlink -T rom_bios.cmd -brawbin1 __store.o __load.o printf_again.o sieve.o -o sieve.bin
#	vlink -T rom_bios.cmd -brawbin1 LEDTest.o -o LEDTest.bin
#	vlink -T rom_bios.cmd -brawbin1 cputest.o -o cputest.bin
#	vlink -T rom_bios.cmd -bsrec37 boot.o -o boot.s37
#	vlink -T rom_bios.cmd -brawbin1 boot.o -o boot.bin
#	vlink -T rom_bios.cmd -brawbin1 add.o -o add.bin
#	bin2ver fibonacci.bin 128 m
#	bin2ver fibonacci.bin 128
	bin2ver boot.bin -b128 m -mod65536
	bin2ver boot.bin -b128 -mod65536
#	bin2ver LEDTest.bin 32 m
#	bin2ver boot.bin 32 m
#	bin2ver cputest.bin 32 m
#	bin2ver add.bin 128
