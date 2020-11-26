test.hex : test.S
	avra -o test.hex -e test.eep test.S

clean :
	rm -f test.hex 
	rm -f test.S.obj
	rm -f test.eep 
	rm -f test.lst
	rm -f test.map

flash :
	avrdude -p m328 -c usbasp -e -U flash:w:test.hex

# $(TARGET).hex: $(TARGET).S
# avra -o $(TARGET).hex -e -$(TARGET).eep $(TARGET).S


#		AVRA: advanced AVR macro assembler (version 1.4.2)
# usage: avra [-f][O|M|I|G] output file type
#            [-o <filename>] output file name
#            [-d <filename>] debug file name
#            [-e <filename>] file name to output EEPROM contents
#            [-l <filename>] generate list file
#            [-m <mapfile>] generate map file
#            [--define <symbol>[=<value>]]
#            [-I <dir>] [--listmac]
#            [--max_errors <number>] [--devices] [--version]
#            [-O e|w|i]
#            [-h] [--help] general help
#            <file to assemble>
#
#   --listfile    -l : Create list file
#   --mapfile     -m : Create map file
#   --define      -D : Define symbol.
#   --includedir  -I : Additional include paths. Default: /usr/local/include/avr
#   --listmac        : List macro expansion in listfile.
#   --max_errors     : Maximum number of errors before exit
#                      (default: 10)
#   --devices        : List out supported devices.
#   --version        : Version information.
#   -O e|w|i         : Issue error/warning/ignore overlapping code.
#   --help, -h       : This help text.