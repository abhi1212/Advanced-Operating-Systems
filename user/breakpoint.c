// program to cause a breakpoint trap

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	asm volatile("int $3");
}
<<<<<<< HEAD

=======
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
