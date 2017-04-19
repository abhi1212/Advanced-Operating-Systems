

max=256

n=0
while [ $n -lt $max ] ; do
	echo "TRAPHANDLER_NOEC(thdlr$n, $n)"
	n=$((n + 1))
done
echo "/* break */"
n=0
while [ $n -lt $max ] ; do
	echo "\t.long thdlr$n"
	n=$((n + 1))
done
