/* DONE */
/*
Copyright (c) 1998 by Sean Luke (hereafter referred to as "the Author")
seanl@cs.umd.edu     http://www.cs.umd.edu/users/seanl/

Permission to use, copy, modify, and distribute the source code and
related materials of this software for any purpose and without fee is
hereby granted, provided the Author's name shall not be used in
advertising or publicity pertaining to this material without the
specific, prior written permission of the Author, acknowledgement
of the author appears prominently in the distributed documentation
of any software application derived from this source code, and this
copyright notice appears in all derived source copies.  SEAN LUKE MAKES
NO REPRESENTATIONS ABOUT THE ACCURACY OR SUITABILITY OF THIS MATERIAL
FOR ANY PURPOSE.  IT IS PROVIDED "AS IS", WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES.

*/


#ifndef _FFT_H
#define _FFT_H

/* fft(float data[], int nn, int isign)
	
This function performs the FFT and inverse FFT.
	
For the FFT (denoted by isign=1), the function takes in data 
a floating-pint array of size nn*2, representing nn complex 
numbers represented as {amplitude, phase} pairs (that is, in
POLAR coordinates, not in CARTESIAN coordinates).  This is
useful for sound manipulation.

For sounds, you should put the sound values in the 
even parts of the array, and zeros in the odd parts of the 
array.  fft returns in data the frequency values from f=-1/nn 
to just below f=1/nn.  Note that nn MUST BE A POWER OF 2, that 
is nn=2^n for some n.
	
The IFFT works in exactly the reverse form. */



/* isign values */
#define FORWARD_FFT 1
#define INVERSE_FFT -1

void fft(float data[], int nn, int isign);

#endif