/** dpcmDecoders.m
Copyright (c) 1998 Jerome Genest.  All rights reserved.
jgenest@gel.ulaval.ca

This source code was insprired from and thus contains parts from:

-C++ framework (in "A Programmer©s guide to sound, Addison-Wesley)
 by Tim Kientzle Copyright 1997.  All rights reserved.

Permission to use, copy, modify, and distribute this material for any
NON-PROFIT purpose is hereby granted. Commercial use of this material
is granted only with the sole permission of Jerome Genest. Both are
provided that this permission notice appear in all source copies, and that
the author's name shall not be used in advertising or publicity pertaining
to this material without the specific, prior written permission of the author.

THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "DpcmDecoders.h"
#import "SoundFormats.h"


static const signed char fibonacci[] = {
   -34, -21, -13, -8, -5, -3, -2, -1, 0, 1, 2, 3, 5, 8, 13, 21
};

static const signed char exponential[] = {
   -128, -64, -32, -16, -8, -4, -2, -1, 0, 1, 2, 4, 8, 16, 32, 64
};


@implementation DpcmFibonacciDecoder
-initWithPrevious:prev
{
[super initWithPrevious:prev];
previousValue = 0;

return self;
}



-(long) getSamples:(void *)buffer forSize: (long) length 
 {
short *sampleBuffer = buffer;
   unsigned char *byteBuffer = (unsigned char *)(buffer)
	+ length * sizeof(short) // buffer length
         - length / 2 ; // Space needed for compressed data
  

   // Read encoded data into the buffer
   long bytesRead = [self readBytes:byteBuffer forSize:length/2];
   long i;
   for(i=0; i<bytesRead; i++) 
	{
      	// Decode low-order nybble
      	int nybble = ((int)(*byteBuffer>>4)+8)&0xF;
      	previousValue += (short)(fibonacci[nybble])<< ((sizeof(short)-1)*8);
        *sampleBuffer++ = previousValue;
        // Decode high-order nybble
        nybble = ((int)(*byteBuffer)+8)&0xF;
      	previousValue +=(short)(fibonacci[nybble])<< ((sizeof(short)-1)*8);
      	*sampleBuffer++ = previousValue;
   	}
   return bytesRead * 2;
}

-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(short) inputFormat
{
return SND_FORMAT_DPCM_FIBO;
}

@end


@implementation DpcmExponentialDecoder

-initWithPrevious:prev
{
[super initWithPrevious:prev];
previousValue = 0;

return self;
}

-(long) getSamples:(void *)buffer forSize: (long) length
{
short *sampleBuffer = buffer;
unsigned char *byteBuffer = (unsigned char*)(buffer)
         + length * sizeof(short) // buffer length
         - length / 2 ; // Space needed for compressed data
   

   // Read encoded data into the buffer
   long bytesRead = [self readBytes:byteBuffer forSize:length/2];
   long i;
   for(i=0; i<bytesRead; i++) 
	{
      	// Decode low-order nybble
      	int nybble = ((int)(*byteBuffer>>4)+8)&0xF;
      	previousValue +=(short)(exponential[nybble])<< ((sizeof(short)-1)*8);
        *sampleBuffer++ = previousValue;
        // Decode high-order nybble
        nybble = ((int)(*byteBuffer)+8)&0xF;
      	previousValue +=(short)(exponential[nybble])<< ((sizeof(short)-1)*8);
        *sampleBuffer++ = previousValue;
     	}
   return bytesRead * 2;
}

-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(short) inputFormat
{
return SND_FORMAT_DPCM_EXP;
}
@end