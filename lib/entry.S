#include <inc/mmu.h>
#include <inc/memlayout.h>

.data
<<<<<<< HEAD
// Define the global symbols 'envs', 'pages', 'vpt', and 'vpd'
=======
// Define the global symbols 'envs', 'pages', 'uvpt', and 'uvpd'
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
// so that they can be used in C as if they were ordinary global arrays.
	.globl envs
	.set envs, UENVS
	.globl pages
	.set pages, UPAGES
<<<<<<< HEAD
	.globl vpt
	.set vpt, UVPT
	.globl vpd
	.set vpd, (UVPT+(UVPT>>12)*4)
=======
	.globl uvpt
	.set uvpt, UVPT
	.globl uvpd
	.set uvpd, (UVPT+(UVPT>>12)*4)
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5


// Entrypoint - this is where the kernel (or our parent environment)
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
	jne args_exist

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
	pushl $0

args_exist:
	call libmain
1:	jmp 1b

