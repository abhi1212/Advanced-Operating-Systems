# env.mk - configuration variables for the JOS lab

# '$(V)' controls whether the lab makefiles print verbose commands (the
# actual shell commands run by Make), as well as the "overview" commands
# (such as '+ cc lib/readline.c').
#
# For overview commands only, the line should read 'V = @'.
# For overview and verbose commands, the line should read 'V ='.
V = @

# If your system-standard GNU toolchain is ELF-compatible, then comment
# out the following line to use those tools (as opposed to the i386-jos-elf
# tools that the 6.828 make system looks for by default).
#
# GCCPREFIX=''

<<<<<<< HEAD
# build on cygwin with following
KERNEL_NAME=$(shell uname -s)
ifeq ($(KERNEL_NAME),Linux)
=======
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
# If the makefile cannot find your QEMU binary, uncomment the
# following line and set it to the full path to QEMU.
#
# QEMU=
<<<<<<< HEAD
#QEMU=/usr/local/qemuose/bin/qemu
#QEMUEXTRA=-nographic
else
CROSS_COMPILE=/usr/local/cross/bin/i586-elf-
endif

GCCPREFIX=$(CROSS_COMPILE)

=======
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
