//用~和&实现^   非11且非00则为1
int bitXor(int x, int y){
	return ~(~x&~y)&~(x&y);
}

//int型为32位，最小补码字符码为1其余为0
int tmin(void){
	return 0x1<<31;
}

//是否为补码最大值 即01111...
int isTmax(int x){
	int y = ~(x + x + 1);
	int z = !(x + 1);
	return !(y+z);
}

//是否奇数位都为1
int allOddBits(int x) {
	int y = 0x55 + (0x55 << 8);
	y = y + (y << 16);
	return !~(x | y);
}

//不用-号求-x
int negate(int x) {
	return ~x + 1;
}

//计算是否为0-9的ascii (0x30-0x39)
int isAsciiDigit(int x) {
	int y = ~0x30 + 1;
	int z = ~0x39 + 1;
	int xpy = (x + y) >> 31; //0000...0
	int xpz = (x + z - 1) >> 31; //1111...1
	return !(xpy | ~xpz);
}

//实现x?y:z三目运算
int conditional(int x, int y, int z) {
	x = !!x;
	x = ~x + 1;
	return (x&y) | (~x&z);
}

//实现<=
int isLessOrEqual(int x, int y) {
	int negx = ~x + 1;
	int z = (y + negx) >> 31;	
	int xsign = x >> 31;   
	int ysign = y >> 31;   
	int sXor = xsign^ysign;
	return (!z & !sXor) | !~(xsign & ~ysign);
}

//实现！
int logicalNeg(int x) {
	return ((x | (~x + 1)) >> 31) + 1;
}

//求一个数用补码表示至少需要几位
int howManyBits(int x) {
	int b0, b1, b2, b4, b8, b16;
	int sign = x >> 31;
	x = (sign&~x) | (~sign&x);
	b16 = !!(x >> 16) << 4;
	x = x >> b16;
	b8 = !!(x >> 8) << 3;
	x = x >> b8;
	b4 = !!(x >> 4) << 2;
	x = x >> b4;
	b2 = !!(x >> 2) << 1;
	x = x >> b2;
	b1 = !!(x >> 1);
	x = x >> b1;
	b0 = x;
	return 1 + b0 + b1 + b2 + b4 + b8 + b16;
}

//float
/*
* floatScale2 - Return bit-level equivalent of expression 2*f for
*   floating point argument f.
*   Both the argument and result are passed as unsigned int's, but
*   they are to be interpreted as the bit-level representation of
*   single-precision floating point values.
*   When argument is NaN, return argument
*   Legal ops: Any integer/unsigned operations incl. ||, &&. also if, while
*   Max ops: 30
*   Rating: 4
*/
unsigned floatScale2(unsigned uf) {
	int exp = (uf & 0x7f800000) >> 23;
	int sign = uf & 0x80000000;
	if (exp == 0) {
		return uf << 1 | sign;
	}
	if (exp == 255) {
		return uf;
	}	
	exp++;
	if (exp == 255) {
		return 0x7f800000 | sign;
	}
	return (exp << 23) | (uf & 0x807fffff);
}
/*
* floatFloat2Int - Return bit-level equivalent of expression (int) f
*   for floating point argument f.
*   Argument is passed as unsigned int, but
*   it is to be interpreted as the bit-level representation of a
*   single-precision floating point value.
*   Anything out of range (including NaN and infinity) should return
*   0x80000000u.
*   Legal ops: Any integer/unsigned operations incl. ||, &&. also if, while
*   Max ops: 30
*   Rating: 4
*/
int floatFloat2Int(unsigned uf) {
	if (!(uf & 0x7fffffff)) {
		return 0;
	}

	int sign = uf >> 31;
	int exp = ((uf & 0x7f800000) >> 23) - 127;
	int frac = (uf & 0x007fffff) | 0x00800000;

	if (exp > 31) {
		return 0x80000000;
	}

	if (exp < 0) {
		return 0;
	}

	if (exp > 23) {
		frac <<= (exp - 23);
	}
	else {
		frac >>= (23 - exp);
	}

	if (!((frac >> 31) ^ sign)) {
		return frac;
	}
	else if (frac >> 31) {
		return 0x80000000;
	}
	else {
		return ~frac + 1;
	}
}
/*
* floatPower2 - Return bit-level equivalent of the expression 2.0^x
*   (2.0 raised to the power x) for any 32-bit integer x.
*
*   The unsigned value that is returned should have the identical bit
*   representation as the single-precision floating-point number 2.0^x.
*   If the result is too small to be represented as a denorm, return
*   0. If too large, return +INF.
*
*   Legal ops: Any integer/unsigned operations incl. ||, &&. Also if, while
*   Max ops: 30
*   Rating: 4
*/
unsigned floatPower2(int x) {
	unsigned INF = 0xff << 23;
	int exp = x + 127;
	if (exp <= 0) return 0;
	if (exp >= 255) return INF;
	return exp << 23;
}