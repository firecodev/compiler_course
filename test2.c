void main()
{
		int a;
		int b, c;

		// This is one line comment.
		
		/* This is block comment.
		*/



		if (1 > 0)
			if (1 > 2) {
				a = 9;
				if (3 < 4)
					b=4;
				else
					b=5;
			}
			else {
				a = 99;
				b = 7;
				c = 6;
				while (c < 20) {
					for(b = 50; c < 10; b = b + 1)
						c = c + 7;
					c = c + 8;
				}
			}
		
		printf("%d\n", a);
		printf("%d\n", b);
		printf("%d\n", c);
}
