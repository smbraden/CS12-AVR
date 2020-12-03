
TARGET = test
ASSEMBLER = avra
# ASSEMBLER = avr-as
MCU = m328

ifeq ($(ASSEMBLER), avra)

$(TARGET).hex : $(TARGET).S
	avra -o $(TARGET).hex -e $(TARGET).eep $(TARGET).S


clean :
	rm -f *.hex 
	rm -f *.S.obj
	rm -f *.eep 
	rm -f *.lst
	rm -f *.map

else	
# the avr-as build instructions are incomplete
$(TARGET).out : $(TARGET).S
	avr-as $(TARGET).S $(TARGET).out

$(TARGET).hex : $(TARGET).out
	avr-objcopy -j .text -j .data -O ihex $(TARGET).out $(TARGET).hex

endif


flash :
	avrdude -p $(MCU) -c usbasp -e -U flash:w:$(TARGET).hex

flash328 :
	avrdude -p m328 -c usbasp -e -U flash:w:$(TARGET).hex

flash168 :
	avrdude -p m168 -c usbasp -e -U flash:w:$(TARGET).hex


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