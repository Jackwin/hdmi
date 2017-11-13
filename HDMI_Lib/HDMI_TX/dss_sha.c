//////////////////////////////////////////////////////////////////////
// DSS_SHA.C
//
// DO DSS SHA caculation code.
//////////////////////////////////////////////////////////////////////
#define _DSS_SHA_

// #define _DSS_SHA_
#include "hdmitx.h"
#ifdef SUPPORT_DSSSHA

/*
 * LongNumber routines for DSS and SHA calculating.
 */

USHORT bnZero[1] = { 0 };
USHORT bnOne[2] = { 1,1 };

/*
 * The LongNumber format is an array of 'unsigned short'. The first
 * element of the array counts the remaining elements. The
 * remaining elements express the actual number,base 2^16,_least_
 * significant digit first. (So it's trivial to extract the bit
 * with value 2^n for any n.)
 *													  fopen
 * All LongNumbers in this module are positive. Negative numbers must
 * be dealt with outside it.
 *
 * INVARIANT: the most significant word of any LongNumber must be
 * nonzero.
 */

LongNumber Zero = bnZero,One = bnOne;

/*************************************************************************/
static LongNumber newbn(LONG length)
{
	LongNumber b = malloc((length + 1) * sizeof(USHORT));
	if (!b)
		abort();					   /* FIXME */
	memset(b,0,(length + 1) * sizeof(*b));
	b[0] = (USHORT)length;
	return b;
}

/*************************************************************************/
LongNumber ln_copy(LongNumber orig)
{
	LongNumber b = malloc((orig[0] + 1) * sizeof(USHORT));
	if (!b)
		abort();					   /* FIXME */
	memcpy(b,orig,(orig[0] + 1) * sizeof(*b));
	return b;
}

/************************************************************************/
void ln_free(LongNumber b)
{
	/*
	 * Burn the evidence,just in case.
	 */
	memset(b,0,sizeof(b[0]) * (b[0] + 1));
	free(b);
}

/*
 * Compare two bignums. Returns like strcmp.
 */
LONG ln_cmp(LongNumber a,LongNumber b)
{
	LONG amax = a[0],bmax = b[0];
	LONG i = (amax > bmax ? amax : bmax);
	while (i) {
		USHORT aval = (i > amax ? 0 : a[i]);
		USHORT bval = (i > bmax ? 0 : b[i]);
		if (aval < bval)
			return -1;
		if (aval > bval)
			return +1;
		i--;
	}
	return 0;
}
/******************************************************************************/
static void internal_add_shifted(
	USHORT *number,
	unsigned n,LONG shift)
{
	LONG word = 1 + (shift / 16);
	LONG bshift = shift % 16;
	ULONG addend;

	addend = n << bshift;

	while (addend) {
		addend += number[word];
		number[word] = (USHORT) addend & 0xFFFF;
		addend >>= 16;
		word++;
	}
}
/*
 * Compute c = a * b.
 * Input is in the first len words of a and b.
 * Result is returned in the first 2*len words of c.
 */
static void internal_mul(
	USHORT *a,USHORT *b,
	USHORT *c,LONG len)
{
	LONG i,j;
	ULONG ai,t;

	for (j = 0; j < 2 * len; j++)
		c[j] = 0;

	for (i = len - 1; i >= 0; i--) {
		ai = a[i];
		t = 0;
		for (j = len - 1; j >= 0; j--) {
			t += ai * (ULONG) b[j];
			t += (ULONG) c[i + j + 1];
			c[i + j + 1] = (USHORT) t;
			t = t >> 16;
		}
		c[i] = (USHORT) t;
	}
}

/******************************************************************************/
/*
 * Compute a = a % m.
 * Input in first alen words of a and first mlen words of m.
 * Output in first alen words of a
 * (of which first alen-mlen words will be zero).
 * The MSW of m MUST have its high bit set.
 * Quotient is accumulated in the 'quotient' array,which is a LongNumber
 * rather than the internal bigendian format. Quotient parts are shifted
 * left by 'qshift' before adding into quot.
 */

static void internal_mod(
	USHORT *a,LONG alen,
	USHORT *m,LONG mlen,
	USHORT *quot,LONG qshift)
{
	USHORT m0,m1;
	ULONG h;
	LONG i,k;

	m0 = m[0];
	if (mlen > 1)
		m1 = m[1];
	else
		m1 = 0;

	for (i = 0; i <= alen - mlen; i++) {
		ULONG t;
		ULONG q,r,c,ai1;

		if (i == 0) {
			h = 0;
		} else {
			h = a[i - 1];
			a[i - 1] = 0;
		}

		if (i == alen - 1)
			ai1 = 0;
		else
			ai1 = a[i + 1];

		/* Find q = h:a[i] / m0 */
		t = ((ULONG) h << 16) + a[i];
		q = t / m0;
		r = t % m0;

		/* Refine our estimate of q by looking at
		   h:a[i]:a[i+1] / m0:m1 */
		t = (LONG) m1 *(LONG) q;
		if (t > ((ULONG) r << 16) + ai1) {
			q--;
			t -= m1;
			r = (r + m0) & 0xffff;	 /* overflow? */
			if (r >= (ULONG) m0 &&
				t > ((ULONG) r << 16) + ai1) q--;
		}

		/* Subtract q * m from a[i...] */
		c = 0;
		for (k = mlen - 1; k >= 0; k--) {
			t = (LONG) q *(LONG) m[k];
			t += c;
			c = t >> 16;
			if ((USHORT) t > a[i + k])
				c++;
			a[i + k] -= (USHORT) t;
		}

		/* Add back m in case of borrow */
		if (c != h) {
			t = 0;
			for (k = mlen - 1; k >= 0; k--) {
				t += m[k];
				t += a[i + k];
				a[i + k] = (USHORT) t;
				t = t >> 16;
			}
			q--;
		}
		if (quot)
			internal_add_shifted(quot,q,qshift + 16 * (alen - mlen - i));
	}
}
/******************************************************************************/
/*
 * Compute (base ^ exp) % mod.
 * The base MUST be smaller than the modulus.
 * The most significant word of mod MUST be non-zero.
 * We assume that the result array is the same size as the mod array.
 */
LongNumber modpow(LongNumber base,LongNumber exp,LongNumber mod)
{
	USHORT *a,*b,*n,*m;
	LONG mshift;
	LONG mlen,i,j;
	LongNumber result;

	/* Allocate m of size mlen,copy mod to m */
	/* We use big endian internally */
	mlen = mod[0];
	m = malloc(mlen * sizeof(USHORT));
	for (j = 0; j < mlen; j++)
		m[j] = mod[mod[0] - j];

	/* Shift m left to make msb bit set */
	for (mshift = 0; mshift < 15; mshift++)
		if ((m[0] << mshift) & 0x8000)
			break;
	if (mshift) {
		for (i = 0; i < mlen - 1; i++)
			m[i] = (m[i] << mshift) | (m[i + 1] >> (16 - mshift));
		m[mlen - 1] = m[mlen - 1] << mshift;
	}

	/* Allocate n of size mlen,copy base to n */
	n = malloc(mlen * sizeof(USHORT));
	i = mlen - base[0];
	for (j = 0; j < i; j++)
		n[j] = 0;
	for (j = 0; j < base[0]; j++)
		n[i + j] = base[base[0] - j];

	/* Allocate a and b of size 2*mlen. Set a = 1 */
	a = malloc(2 * mlen * sizeof(USHORT));
	b = malloc(2 * mlen * sizeof(USHORT));
	for (i = 0; i < 2 * mlen; i++)
		a[i] = 0;
	a[2 * mlen - 1] = 1;

	/* Skip leading zero bits of exp. */
	i = 0;
	j = 15;
	while (i < exp[0] && (exp[exp[0] - i] & (1 << j)) == 0) {
		j--;
		if (j < 0) {
			i++;
			j = 15;
		}
	}

	/* Main computation */
	while (i < exp[0]) {
		while (j >= 0) {
			internal_mul(a + mlen,a + mlen,b,mlen);
			internal_mod(b,mlen * 2,m,mlen,NULL,0);
			if ((exp[exp[0] - i] & (1 << j)) != 0) {
				internal_mul(b + mlen,n,a,mlen);
				internal_mod(a,mlen * 2,m,mlen,NULL,0);
			} else {
				USHORT *t;
				t = a;
				a = b;
				b = t;
			}
			j--;
		}
		i++;
		j = 15;
	}

	/* Fixup result in case the modulus was shifted */
	if (mshift) {
		for (i = mlen - 1; i < 2 * mlen - 1; i++)
			a[i] = (a[i] << mshift) | (a[i + 1] >> (16 - mshift));
		a[2 * mlen - 1] = a[2 * mlen - 1] << mshift;
		internal_mod(a,mlen * 2,m,mlen,NULL,0);
		for (i = 2 * mlen - 1; i >= mlen; i--)
			a[i] = (a[i] >> mshift) | (a[i - 1] << (16 - mshift));
	}

	/* Copy result to buffer */
	result = newbn(mod[0]);
	for (i = 0; i < mlen; i++)
		result[result[0] - i] = a[i + mlen];
	while (result[0] > 1 && result[result[0]] == 0)
		result[0]--;

	/* Free temporary arrays */
	for (i = 0; i < 2 * mlen; i++)
		a[i] = 0;
	free(a);
	for (i = 0; i < 2 * mlen; i++)
		b[i] = 0;
	free(b);
	for (i = 0; i < mlen; i++)
		m[i] = 0;
	free(m);
	for (i = 0; i < mlen; i++)
		n[i] = 0;
	free(n);

	return result;
}

/******************************************************************************/
/*
 * Compute (p * q) % mod.
 * The most significant word of mod MUST be non-zero.
 * We assume that the result array is the same size as the mod array.
 */
LongNumber modmul(LongNumber p,LongNumber q,LongNumber mod)
{
	USHORT *a,*n,*m,*o;
	LONG mshift;
	LONG pqlen,mlen,rlen,i,j;
	LongNumber result;

	/* Allocate m of size mlen,copy mod to m */
	/* We use big endian internally */
	mlen = mod[0];
	m = malloc(mlen * sizeof(USHORT));
	for (j = 0; j < mlen; j++)
		m[j] = mod[mod[0] - j];

	/* Shift m left to make msb bit set */
	for (mshift = 0; mshift < 15; mshift++)
		if ((m[0] << mshift) & 0x8000)
			break;
	if (mshift) {
		for (i = 0; i < mlen - 1; i++)
			m[i] = (m[i] << mshift) | (m[i + 1] >> (16 - mshift));
		m[mlen - 1] = m[mlen - 1] << mshift;
	}

	pqlen = (p[0] > q[0] ? p[0] : q[0]);

	/* Allocate n of size pqlen,copy p to n */
	n = malloc(pqlen * sizeof(USHORT));
	i = pqlen - p[0];
	for (j = 0; j < i; j++)
		n[j] = 0;
	for (j = 0; j < p[0]; j++)
		n[i + j] = p[p[0] - j];

	/* Allocate o of size pqlen,copy q to o */
	o = malloc(pqlen * sizeof(USHORT));
	i = pqlen - q[0];
	for (j = 0; j < i; j++)
		o[j] = 0;
	for (j = 0; j < q[0]; j++)
		o[i + j] = q[q[0] - j];

	/* Allocate a of size 2*pqlen for result */
	a = malloc(2 * pqlen * sizeof(USHORT));

	/* Main computation */
	internal_mul(n,o,a,pqlen);
	internal_mod(a,pqlen * 2,m,mlen,NULL,0);

	/* Fixup result in case the modulus was shifted */
	if (mshift) {
		for (i = 2 * pqlen - mlen - 1; i < 2 * pqlen - 1; i++)
			a[i] = (a[i] << mshift) | (a[i + 1] >> (16 - mshift));
		a[2 * pqlen - 1] = a[2 * pqlen - 1] << mshift;
		internal_mod(a,pqlen * 2,m,mlen,NULL,0);
		for (i = 2 * pqlen - 1; i >= 2 * pqlen - mlen; i--)
			a[i] = (a[i] >> mshift) | (a[i - 1] << (16 - mshift));
	}

	/* Copy result to buffer */
	rlen = (mlen < pqlen * 2 ? mlen : pqlen * 2);
	result = newbn(rlen);
	for (i = 0; i < rlen; i++)
		result[result[0] - i] = a[i + 2 * pqlen - rlen];
	while (result[0] > 1 && result[result[0]] == 0)
		result[0]--;

	/* Free temporary arrays */
	for (i = 0; i < 2 * pqlen; i++)
		a[i] = 0;
	free(a);
	for (i = 0; i < mlen; i++)
		m[i] = 0;
	free(m);
	for (i = 0; i < pqlen; i++)
		n[i] = 0;
	free(n);
	for (i = 0; i < pqlen; i++)
		o[i] = 0;
	free(o);

	return result;
}

/*
 * Non-modular multiplication and addition.
 */
LongNumber ln_mul_add(LongNumber a,LongNumber b,LongNumber addend)
{
	LONG alen = a[0],blen = b[0];
	LONG mlen = (alen > blen ? alen : blen);
	LONG rlen,i,maxspot;
	USHORT *workspace;
	LongNumber ret;

	/* mlen space for a,mlen space for b,2*mlen for result */
	workspace = malloc(mlen * 4 * sizeof(USHORT));
	for (i = 0; i < mlen; i++) {
		workspace[i] = (mlen - i <= a[0] ? a[mlen - i] : 0);
		workspace[1 * mlen + i] = (mlen - i <= b[0] ? b[mlen - i] : 0);
	}

	internal_mul(workspace + 0 * mlen,workspace + 1 * mlen,
	             workspace + 2 * mlen,mlen);

	/* now just copy the result back */
	rlen = alen + blen + 1;
	if (addend && rlen <= addend[0])
		rlen = addend[0] + 1;
	ret = newbn(rlen);
	maxspot = 0;
	for (i = 1; i <= ret[0]; i++) {
		ret[i] = (i <= 2 * mlen ? workspace[4 * mlen - i] : 0);
		if (ret[i] != 0)
			maxspot = i;
	}
	ret[0] = (USHORT)maxspot;

	/* now add in the addend,if any */
	if (addend) {
		ULONG carry = 0;
		for (i = 1; i <= rlen; i++) {
			carry += (i <= ret[0] ? ret[i] : 0);
			carry += (i <= addend[0] ? addend[i] : 0);
			ret[i] = (USHORT) carry & 0xFFFF;
			carry >>= 16;
			if (ret[i] != 0 && i > maxspot)
				maxspot = i;
		}
	}
	ret[0] = (USHORT)maxspot;

	return ret;
}


/*
 * Compute p % mod.
 * The most significant word of mod MUST be non-zero.
 * We assume that the result array is the same size as the mod array.
 * We optionally write out a quotient if 'quotient' is non-NULL.
 * We can avoid writing out the result if 'result' is NULL.
 */
static void ln_divmod(LongNumber p,LongNumber mod,LongNumber result,LongNumber quotient)
{
	USHORT *n,*m;
	LONG mshift;
	LONG plen,mlen,i,j;

	/* Allocate m of size mlen,copy mod to m */
	/* We use big endian internally */
	mlen = mod[0];
	m = malloc(mlen * sizeof(USHORT));
	for (j = 0; j < mlen; j++)
		m[j] = mod[mod[0] - j];

	/* Shift m left to make msb bit set */
	for (mshift = 0; mshift < 15; mshift++)
		if ((m[0] << mshift) & 0x8000)
			break;
	if (mshift) {
		for (i = 0; i < mlen - 1; i++)
			m[i] = (m[i] << mshift) | (m[i + 1] >> (16 - mshift));
		m[mlen - 1] = m[mlen - 1] << mshift;
	}

	plen = p[0];
	/* Ensure plen > mlen */
	if (plen <= mlen)
		plen = mlen + 1;

	/* Allocate n of size plen,copy p to n */
	n = malloc(plen * sizeof(USHORT));
	for (j = 0; j < plen; j++)
		n[j] = 0;
	for (j = 1; j <= p[0]; j++)
		n[plen - j] = p[j];

	/* Main computation */
	internal_mod(n,plen,m,mlen,quotient,mshift);

	/* Fixup result in case the modulus was shifted */
	if (mshift) {
		for (i = plen - mlen - 1; i < plen - 1; i++)
			n[i] = (n[i] << mshift) | (n[i + 1] >> (16 - mshift));
		n[plen - 1] = n[plen - 1] << mshift;
		internal_mod(n,plen,m,mlen,quotient,0);
		for (i = plen - 1; i >= plen - mlen; i--)
			n[i] = (n[i] >> mshift) | (n[i - 1] << (16 - mshift));
	}

	/* Copy result to buffer */
	if (result) {
		for (i = 1; i <= result[0]; i++) {
			LONG j = plen - i;
			result[i] = j >= 0 ? n[j] : 0;
		}
	}

	/* Free temporary arrays */
	for (i = 0; i < mlen; i++)
		m[i] = 0;
	free(m);
	for (i = 0; i < plen; i++)
		n[i] = 0;
	free(n);
}

/*
 * Modular inverse,using Euclid's extended algorithm.
 */
LongNumber modinv(LongNumber number,LongNumber modulus)
{
	LongNumber a = ln_copy(modulus);
	LongNumber b = ln_copy(number);
	LongNumber xp = ln_copy(Zero);
	LongNumber x = ln_copy(One);
	LONG sign = +1;

	while (ln_cmp(b,One) != 0) {
		LongNumber t = newbn(b[0]);
		LongNumber q = newbn(a[0]);
		ln_divmod(a,b,t,q);
		while (t[0] > 1 && t[t[0]] == 0)
			t[0]--;
		ln_free(a);
		a = b;
		b = t;
		t = xp;
		xp = x;
		x = ln_mul_add(q,xp,t);
		sign = -sign;
		ln_free(t);
	}

	ln_free(b);
	ln_free(a);
	ln_free(xp);

	/* now we know that sign * x == 1,and that x < modulus */
	if (sign < 0) {
		/* set a new x to be modulus - x */
		LongNumber newx = newbn(modulus[0]);
		USHORT carry = 0;
		LONG maxspot = 1;
		LONG i;

		for (i = 1; i <= newx[0]; i++) {
			USHORT aword = (i <= modulus[0] ? modulus[i] : 0);
			USHORT bword = (i <= x[0] ? x[i] : 0);
			newx[i] = aword - bword - carry;
			bword = ~bword;
			carry = carry ? (newx[i] >= bword) : (newx[i] > bword);
			if (newx[i] != 0)
				maxspot = i;
		}
		newx[0] = (USHORT)maxspot;
		ln_free(x);
		x = newx;
	}

	/* and return. */
	return x;
}


LongNumber ln_from_bytes(BYTE *ucdata,LONG nbytes)
{
	LongNumber result;
	LONG w,i;

	w = (nbytes + 1) / 2;			   /* bytes -> words */

	result = newbn(w);
	for (i = 1; i <= w; i++)
		result[i] = 0;
	for (i = nbytes; i--;) {
		BYTE byte = *ucdata++;
		if (i & 1)
			result[1 + i / 2] |= byte << 8;
		else
			result[1 + i / 2] |= byte;
	}

	while (result[0] > 1 && result[result[0]] == 0)
		result[0]--;
	return result;
}



/*
 * SHA1 hash algorithm. Used in SSH2 as a MAC,and the transform is
 * also used as a 'stirring' function for the PuTTY random number
 * pool. Implemented directly from the specification by Simon
 * Tatham.
 */

/* ----------------------------------------------------------------------
 * Core SHA algorithm: processes 16-word blocks into a message digest.
 */

#define rol(x,y) (((x) << (y)) | (((ULONG)x) >> (32-y)))

static void SHA_Core_Init(ULONG h[5])
{
	h[0] = 0x67452301;
	h[1] = 0xefcdab89;
	h[2] = 0x98badcfe;
	h[3] = 0x10325476;
	h[4] = 0xc3d2e1f0;
}

//richard void SHATransform(ULONG * digest,ULONG * block)
static void SHATransform(ULONG * digest,ULONG * block)
{
	ULONG w[80];
	ULONG a,b,c,d,e;
	LONG t;

	for (t = 0; t < 16; t++)
		w[t] = block[t];

	for (t = 16; t < 80; t++) {
		ULONG tmp = w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16];
		w[t] = rol(tmp,1);
	}

	a = digest[0];
	b = digest[1];
	c = digest[2];
	d = digest[3];
	e = digest[4];

	for (t = 0; t < 20; t++) {
		ULONG tmp =
			rol(a,5) + ((b & c) | (d & ~b)) + e + w[t] + 0x5a827999;
		e = d;
		d = c;
		c = rol(b,30);
		b = a;
		a = tmp;
	}
	for (t = 20; t < 40; t++) {
		ULONG tmp = rol(a,5) + (b ^ c ^ d) + e + w[t] + 0x6ed9eba1;
		e = d;
		d = c;
		c = rol(b,30);
		b = a;
		a = tmp;
	}
	for (t = 40; t < 60; t++) {
		ULONG tmp = rol(a,
						 5) + ((b & c) | (b & d) | (c & d)) + e + w[t] +
			0x8f1bbcdc;
		e = d;
		d = c;
		c = rol(b,30);
		b = a;
		a = tmp;
	}
	for (t = 60; t < 80; t++) {
		ULONG tmp = rol(a,5) + (b ^ c ^ d) + e + w[t] + 0xca62c1d6;
		e = d;
		d = c;
		c = rol(b,30);
		b = a;
		a = tmp;
	}

	digest[0] += a;
	digest[1] += b;
	digest[2] += c;
	digest[3] += d;
	digest[4] += e;
}

////////////////////////////////////////////////////////////////////////////////
// Function: CountBits
// Parameter: uData - byte array for count,Size - the size in byte
// Return: number of bit 1 in array.
// Remark: calculating for Revoketion list check.
// Side-Effect:
////////////////////////////////////////////////////////////////////////////////

static ULONG
CountBits(BYTE *uData,ULONG Size)
{
	ULONG i,j,n = 0;
	for (i = 0; i < Size; i++) {
		for (j = 0; j < 8; j++) {
			if (uData[i] & (1 << j)) n++;
		}
	}
	return n;
}

static LongNumber
get160(BYTE **ucdata,ULONG *datalen)
{
	LongNumber b;

	b = ln_from_bytes(*ucdata,20);
	*ucdata += 20;
	*datalen -= 20;

	return b;
}

static BOOL
dss_verifysig(
	void *key,
	BYTE *sig,ULONG siglen,
	BYTE *ucdata,ULONG datalen)
{
	struct dss_key *dss = (struct dss_key *)key;
	BYTE *p;
	ULONG slen;
	BYTE hash[20];
	LongNumber r,s,w,gu1p,yu2p,gu1yu2p,u1,u2,sha,v;
	BOOL ret;

	if (! dss->p)
		return FALSE;
	r = get160(&sig,&siglen);
	s = get160(&sig,&siglen);
	if (!r || !s)
		return FALSE;
	// Step 1. w <- s^-1 mod q.
	w = modinv(s,dss->q);
	// Step 2. u1 <- SHA(message) * w mod q.
	SHA_Simple(ucdata,datalen,hash);
	p = hash;
	slen = 20;
	sha = get160(&p,&slen);
	u1 = modmul(sha,w,dss->q);
	// Step 3. u2 <- r * w mod q.
	u2 = modmul(r,w,dss->q);
	// Step 4. v <- (g^u1 * y^u2 mod p) mod q.
	gu1p = modpow(dss->g,u1,dss->p);
	yu2p = modpow(dss->y,u2,dss->p);
	gu1yu2p = modmul(gu1p,yu2p,dss->p);
	v = modmul(gu1yu2p,One,dss->q);
	// Step 5. v should now be equal to r.
	ret = ! ln_cmp(v,r);

	ln_free(w);
	ln_free(sha);
	ln_free(gu1p);
	ln_free(yu2p);
	ln_free(gu1yu2p);
	ln_free(v);
	ln_free(r);
	ln_free(s);

	return ret;
}

/* ----------------------------------------------------------------------
 * Outer SHA algorithm: take an arbitrary length byte string,
 * convert it into 16-word blocks with the prescribed padding at
 * the end,and pass those blocks to the core SHA algorithm.
 */

void SHA_Init(SHA_State * s)
{
	SHA_Core_Init(s->h);
	s->blkused = 0;
	s->lenhi = s->lenlo = 0;
}

void SHA_Bytes(SHA_State * s,void *p,LONG len)
{
	BYTE *q = (BYTE *) p;
	ULONG wordblock[16];
	ULONG lenw = len;
	LONG i;

	/*
	 * Update the length field.
	 */
	s->lenlo += lenw;
	s->lenhi += (s->lenlo < lenw);

	if (s->blkused && s->blkused + len < 64) {
		/*
		 * Trivial case: just add to the block.
		 */
		memcpy(s->block + s->blkused,q,len);
		s->blkused += len;
	} else {
		/*
		 * We must complete and process at least one block.
		 */
		while (s->blkused + len >= 64) {
			memcpy(s->block + s->blkused,q,64 - s->blkused);
			q += 64 - s->blkused;
			len -= 64 - s->blkused;
			/* Now process the block. Gather bytes big-endian into words */
			for (i = 0; i < 16; i++) {
				wordblock[i] =
					(((ULONG) s->block[i * 4 + 0]) << 24) |
					(((ULONG) s->block[i * 4 + 1]) << 16) |
					(((ULONG) s->block[i * 4 + 2]) << 8) |
					(((ULONG) s->block[i * 4 + 3]) << 0);
			}
			SHATransform(s->h,wordblock);
			s->blkused = 0;
		}
		memcpy(s->block,q,len);
		s->blkused = len;
	}
}

void SHA_Final(SHA_State * s,BYTE *output)
{
	LONG i;
	LONG pad;
	BYTE c[64];
	ULONG lenhi,lenlo;

	if (s->blkused >= 56)
		pad = 56 + 64 - s->blkused;
	else
		pad = 56 - s->blkused;

	lenhi = (s->lenhi << 3) | (s->lenlo >> (32 - 3));
	lenlo = (s->lenlo << 3);

	memset(c,0,pad);
	c[0] = 0x80;
	SHA_Bytes(s,&c,pad);

	c[0] = (BYTE)((lenhi >> 24) & 0xFF);
	c[1] = (BYTE)((lenhi >> 16) & 0xFF);
	c[2] = (BYTE)((lenhi >> 8) & 0xFF);
	c[3] = (BYTE)((lenhi >> 0) & 0xFF);
	c[4] = (BYTE)((lenlo >> 24) & 0xFF);
	c[5] = (BYTE)((lenlo >> 16) & 0xFF);
	c[6] = (BYTE)((lenlo >> 8) & 0xFF);
	c[7] = (BYTE)((lenlo >> 0) & 0xFF);

	SHA_Bytes(s,&c,8);

	for (i = 0; i < 5; i++) {
		output[i * 4] = (BYTE)((s->h[i] >> 24) & 0xFF);
		output[i * 4 + 1] = (BYTE)((s->h[i] >> 16) & 0xFF);
		output[i * 4 + 2] = (BYTE)((s->h[i] >> 8) & 0xFF);
		output[i * 4 + 3] = (BYTE)((s->h[i]) & 0xFF);
	}
}

void SHA_Simple(void *p,LONG len,BYTE *output)
{
	SHA_State s;

	SHA_Init(&s);
	SHA_Bytes(&s,p,len);
	SHA_Final(&s,output);
}

////////////////////////////////////////////////////////////////////////////////
// Function: HDCP_VerifyRevocationList
// Parameter: pSRM - the SRM array to check revokting list
//            pBKSV - the checking KSV ,pointer of 5 bytes.
//            revoked - pointer of BOOL to return if revoked.
// Return: ER_SUCCESS if information getting correct,ER_FAIL otherwise
// Remark: to check if the KSV of receiver valid.
// Side-Effect: N/A.
////////////////////////////////////////////////////////////////////////////////

static _CODE BYTE y[128] =
{
	0xc7,0x06,0x00,0x52,0x6b,0xa0,0xb0,0x86,0x3a,0x80,0xfb,0xe0,0xa3,0xac,0xff,0x0d,
	0x4f,0x0d,0x76,0x65,0x8a,0x17,0x54,0xa8,0xe7,0x65,0x47,0x55,0xf1,0x5b,0xa7,0x8d,
	0x56,0x95,0x0e,0x48,0x65,0x4f,0x0b,0xbd,0xe1,0x68,0x04,0xde,0x1b,0x54,0x18,0x74,
	0xdb,0x22,0xe1,0x4f,0x03,0x17,0x04,0xdb,0x8d,0x5c,0xb2,0xa4,0x17,0xc4,0x56,0x6c,
	0x27,0xba,0x97,0x3c,0x43,0xd8,0x4e,0x0d,0xa2,0xa7,0x08,0x56,0xfe,0x9e,0xa4,0x8d,
	0x87,0x25,0x90,0x38,0xb1,0x65,0x53,0xe6,0x62,0x43,0x5f,0xf7,0xfd,0x52,0x06,0xe2,
	0x7b,0xb7,0xff,0xbd,0x88,0x6c,0x24,0x10,0x95,0xc8,0xdc,0x8d,0x66,0xf6,0x62,0xcb,
    0xd8,0x8f,0x9d,0xf7,0xe9,0xb3,0xfb,0x83,0x62,0xa9,0xf7,0xfa,0x36,0xe5,0x37,0x99
};

// DSS Public Key - Prime Modulus
static _CODE BYTE p[128] = {
	0xd3,0xc3,0xf5,0xb2,0xfd,0x17,0x61,0xb7,0x01,0x8d,0x75,0xf7,0x93,0x43,0x78,0x6b,
	0x17,0x39,0x5b,0x35,0x5a,0x52,0xc7,0xb8,0xa1,0xa2,0x4f,0xc3,0x6a,0x70,0x58,0xff,
	0x8e,0x7f,0xa1,0x64,0xf5,0x00,0xe0,0xdc,0xa0,0xd2,0x84,0x82,0x1d,0x96,0x9e,0x4b,
	0x4f,0x34,0xdc,0x0c,0xae,0x7c,0x76,0x67,0xb8,0x44,0xc7,0x47,0xd4,0xc6,0xb9,0x83,
	0xe5,0x2b,0xa7,0x0e,0x54,0x47,0xcf,0x35,0xf4,0x04,0xa0,0xbc,0xd1,0x97,0x4c,0x3a,
	0x10,0x71,0x55,0x09,0xb3,0x72,0x15,0x30,0xa7,0x3f,0x32,0x07,0xb9,0x98,0x20,0x49,
	0x5c,0x7b,0x9c,0x14,0x32,0x75,0x73,0x3b,0x02,0x8a,0x49,0xfd,0x96,0x89,0x19,0x54,
	0x2a,0x39,0x95,0x1c,0x46,0xed,0xc2,0x11,0x8c,0x59,0x80,0x2b,0xf3,0x28,0x75,0x27};

// DSS Public Key - Prime Divisor
static _CODE BYTE q[20] = {
	0xee,0x8a,0xf2,0xce,0x5e,0x6d,0xb5,0x6a,0xcd,0x6d,
	0x14,0xe2,0x97,0xef,0x3f,0x4d,0xf9,0xc7,0x08,0xe7};

// DSS Public Key - Generator
static _CODE BYTE g[128] = {
	0x92,0xf8,0x5d,0x1b,0x6a,0x4d,0x52,0x13,0x1a,0xe4,0x3e,0x24,0x45,0xde,0x1a,0xb5,
	0x02,0xaf,0xde,0xac,0xa9,0xbe,0xd7,0x31,0x5d,0x56,0xd7,0x66,0xcd,0x27,0x86,0x11,
	0x8f,0x5d,0xb1,0x4a,0xbd,0xec,0xa9,0xd2,0x51,0x62,0x97,0x7d,0xa8,0x3e,0xff,0xa8,
	0x8e,0xed,0xc6,0xbf,0xeb,0x37,0xe1,0xa9,0x0e,0x29,0xcd,0x0c,0xa0,0x3d,0x79,0x9e,
	0x92,0xdd,0x29,0x45,0xf7,0x78,0x58,0x5f,0xf7,0xc8,0x35,0x64,0x2c,0x21,0xba,0x7f,
	0xb1,0xa0,0xb6,0xbe,0x81,0xc8,0xa5,0xe3,0xc8,0xab,0x69,0xb2,0x1d,0xa5,0x42,0x42,
	0xc9,0x8e,0x9b,0x8a,0xab,0x4a,0x9d,0xc2,0x51,0xfa,0x7d,0xac,0x29,0x21,0x6f,0xe8,
	0xb9,0x3f,0x18,0x5b,0x2f,0x67,0x40,0x5b,0x69,0x46,0x24,0x42,0xc2,0xba,0x0b,0xd9};

SYS_STATUS
HDCP_VerifyRevocationList(BYTE *pSRM,BYTE *pBKSV,BYTE *revoked)
{
    SYS_STATUS err = ER_SUCCESS;
    ULONG SRMVer,VecRevocListLength,MLength,NumKeys;
    struct dss_key dss;
    ULONG i,j,match;



    if((!pSRM)||(!revoked))
    {
        ErrorF("Invalid Param\n") ;
        return ER_FAIL ;
    }

	SRMVer = (pSRM[2] << 8) | pSRM[3];
	VecRevocListLength = (pSRM[5] << 16) | (pSRM[6] << 8) | pSRM[7];
	NumKeys = pSRM[8] & 0x7F;
	MLength = VecRevocListLength - 40 + 5;  // 3 bytes for VecRevocListLength are already included in it
	if (VecRevocListLength < 43) {
		ErrorF("SRM file format error!\n");
		return ER_FAIL;
	} else if (VecRevocListLength <= 44) {
		ErrorF("The SRM message does not contain any revocation keys\n");
		NumKeys = 0;
	} else if (9 + NumKeys * 5 > MLength) {
		ErrorF("The number of revokation keys is greater than the available ucdata!\n");
		return ER_FAIL;
	} else {
		ErrorF("The SRM message contains %d revocation key(s)\n",NumKeys);
	}

	// check DSS SHA1 signature
	dss.y = ln_from_bytes(y,128);
	dss.p = ln_from_bytes(p,128);
	dss.q = ln_from_bytes(q,20);
	dss.g = ln_from_bytes(g,128);
	if (dss_verifysig(&dss,&pSRM[MLength],40,pSRM,MLength)) {
		ErrorF("SRM Signature is correct!\n");
	} else {
		ErrorF("SRM Signature does not match!\n");
		err = ER_FAIL;  // check revoked keys regardless of signature match
		//return ER_FAIL;  // don't check revoked keys unless signature matches
	}

	// Match BKSV against revocation keys
	for (i = 0; i < NumKeys; i++) {
		match = 0;

		if (CountBits(&pSRM[9 + i * 5],5) != 20) {
			ErrorF("Revokation key invalid!\n");
			continue;
		}
		for (j = 0; j < 5; j++) {
			if (pSRM[j + 9 + i * 5] == pBKSV[j]) match++;
		}
		if (match == 5) *revoked = TRUE;
	}


    return ER_SUCCESS ;
}

#endif // SUPPORT_DSSSHA
