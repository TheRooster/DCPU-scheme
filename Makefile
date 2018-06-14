#simple makefile to compile and run a dscm program

run: main.bin
	mono ../../Emulator/Lettuce.exe main.bin 

main.bin: main.dasm
	../../DASM/dasm main.dasm main.bin

main.dasm: main.dscm *.scm
	sagittarius main.dscm > main.dasm 

clean:
	rm -f *.dasm *.bin
