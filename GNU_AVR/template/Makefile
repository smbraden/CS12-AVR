TARGET		= replaceMe
ASSEMBLER	= avra
# ASSEMBLER = avr-as
MCU			= m328
PROGRAMMER	= usbasp 

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
