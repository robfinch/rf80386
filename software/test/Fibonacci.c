
int Fibonacci(int n)
{
	int x;
	int f0,f1,f2;
	
	f0 = 0;
	f1 = 1;
	for (x = 2; x < n; x++) {
		f2 = f0 + f1;
		f0 = f1;
		f1 = f2;
	}
	return (f0);
}

