# CS12-AVR
 An embedded AVR assembly project. This is my proposed final project for CS12, Assembly Language & Computer Architecture (86x64).
 
 ## Resources & References 
 
 [Atmel includes](https://github.com/DarkSector/AVR/tree/master/asm/include)
 
 [AVR Instruction Set Atmel 2016](http://ww1.microchip.com/downloads/en/devicedoc/atmel-0856-avr-instruction-set-manual.pdf)
 [AVR Instruction Set Microchip 2020](http://ww1.microchip.com/downloads/en/DeviceDoc/AVR-Instruction-Set-Manual-DS40002198A.pdf)
 
 [AVR Assembler Tutorials](http://www.avr-asm-tutorial.net/avr_en/beginner/index.html)
 
 [Beginners Introduction to the Assembly Language of ATMEL-AVR-Microcontrollers](http://www.avr-asm-download.de/beginner_en.pdf)
 
 [ATmega48A/PA/88A/PA/168A/PA/328/P Data Sheet](http://ww1.microchip.com/downloads/en/DeviceDoc/ATmega48A-PA-88A-PA-168A-PA-328-P-DS-DS40002061B.pdf)
 
 [AVR Simulator](http://atmel-studio-doc.s3-website-us-east-1.amazonaws.com/webhelp/GUID-54E8AE06-C4C4-430C-B316-1C19714D122B-en-US-1/GUID-C73F1111-250E-4106-B5E5-85A512B75E8B.html)
 
 [Atmel Studio](https://ww1.microchip.com/downloads/en/DeviceDoc/Getting-Started-with-Atmel-Studio7.pdf)

 ## Flashing

As of writing, programmers supported by Atmel Studio IDE include
* STK500
* J-Link (over IP)

The hex file can also be flashed to the MCU using another avrdude-supported ISP programmer. The command for flashing Hello_AtmelStudio using a USBasp programmer is the following:

 `avrdude -p m328 -c usbasp -e -U flash:w:Hello_AtmelStudio.hex`
 
