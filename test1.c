void main()
{
		int a, b;
		int c;

		b = 0;
		c = 1;

		for ( a = 1; a < 100; a=a+2) {
			b = b + 3;
			while (c < 5)
			  c = b + 7;
		}

		printf("%d\n", a);
		printf("%d\n", b);
		printf("%d\n", c);
}
