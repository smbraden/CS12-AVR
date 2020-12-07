# GNU AVR
This Directory provides a script for generating a basic avr assembly project in a GNU/Linux environment. The project is intialized with a VS Code workspace (my prefered editor), as well as a Makefile. 

# To create a project
`cd template`

`./createProject fooBar`

# To build and flash the executable
`cd fooBar`

`make`

## To create a project
`cd ~/CS12-AVR/GNU_AVR/template`

`./createProject fooBar`

`cd ~/CS12-AVR/GNU_AVR/fooBar`

## To assemble and flash the executable
`cd ~/CS12-AVR/GNU_AVR/fooBar`

`make`

`make flash`
