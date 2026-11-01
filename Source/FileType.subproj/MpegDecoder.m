/** mpegDecoder.m
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

#import <AppKit/AppKit.h>
#import "AudioProcessor.h"
#import "SoundFormats.h"
#import "MpegReader.h" 
#import "MpegDecoder.h"
#import "ErrorHandler.h"

int masks[] = {0,1,3,7,0xF,0x1F,0x3F,0x7F,0xFF};

static short bitRateTable[2][4][16] = { // ID, Layer, Code
{  // ID bit == 0 for MPEG 2 lower bitrates
   {0 }, // Reserved
   // Layer 1
   {0,32,48,56,64,80,96,112,128,144,160,176,192,224,256,0 },
   // Layer 2 and 3 are the same
   {0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,0 },
   {0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,0 },
}, {  // ID bit == 1 for MPEG 1 bitrates
   {0 }, // Reserved
   // Layer 1
   {0,32,64,96,128,160,192,224,256,288,320,352,384,416,448,0 },
   // Layer 2
   {0,32,48,56,64,80,96,112,128,160,192,224,256,320,384,0 },
   // Layer 3
   {0,32,40,48,56,64,80,96,112,128,160,192,224,256,320,0 },
}};

static long samplingRateTable[2][4] = { // ID, Code
   {22050,24000,16000,0},  // MPEG 2 sampling rates
   {44100,48000,32000,0}   // MPEG 1 sampling rates
};

static long SynthesisWindowCoefficients[] = // 2.16 fixed-point values
{0, -1, -1, -1, -1, -1, -1, -2, -2, -2, -2, -3, -3, -4, -4, -5, -5, -6,
-7, -7, -8, -9, -10, -11, -13, -14, -16, -17, -19, -21, -24, -26,

-29, -31, -35, -38, -41, -45, -49, -53, -58, -63, -68, -73, -79,
-85, -91, -97, -104, -111, -117, -125, -132, -139, -147, -154, -161,
-169, -176, -183, -190, -196, -202, -208,

213, 218, 222, 225, 227, 228, 228, 227, 224, 221, 215, 208, 200, 189,
177, 163, 146, 127, 106, 83, 57, 29, -2, -36, -72, -111, -153, -197,
-244, -294, -347, -401,

-459, -519, -581, -645, -711, -779, -848, -919, -991, -1064, -1137,
-1210, -1283, -1356, -1428, -1498, -1567, -1634, -1698, -1759, -1817,
-1870, -1919, -1962, -2001, -2032, -2057, -2075, -2085, -2087, -2080,
-2063,

2037, 2000, 1952, 1893, 1822, 1739, 1644, 1535, 1414, 1280, 1131, 970,
794, 605, 402, 185, -45, -288, -545, -814, -1095, -1388, -1692, -2006,
-2330, -2663, -3004, -3351, -3705, -4063, -4425, -4788,

-5153, -5517, -5879, -6237, -6589, -6935, -7271, -7597, -7910, -8209,
-8491, -8755, -8998, -9219, -9416, -9585, -9727, -9838, -9916, -9959,
-9966, -9935, -9863, -9750, -9592, -9389, -9139, -8840, -8492, -8092,
-7640, -7134,

6574, 5959, 5288, 4561, 3776, 2935, 2037, 1082, 70, -998, -2122,
-3300, -4533, -5818, -7154, -8540, -9975, -11455, -12980, -14548,
-16155, -17799, -19478, -21189, -22929, -24694, -26482, -28289,
-30112, -31947, -33791, -35640,

-37489, -39336, -41176, -43006, -44821, -46617, -48390, -50137,
-51853, -53534, -55178, -56778, -58333, -59838, -61289, -62684,
-64019, -65290, -66494, -67629, -68692, -69679, -70590, -71420,
-72169, -72835, -73415, -73908, -74313, -74630, -74856, -74992,

75038, 74992, 74856, 74630, 74313, 73908, 73415, 72835, 72169, 71420,
70590, 69679, 68692, 67629, 66494, 65290, 64019, 62684, 61289, 59838,
58333, 56778, 55178, 53534, 51853, 50137, 48390, 46617, 44821, 43006,
41176, 39336,

37489, 35640, 33791, 31947, 30112, 28289, 26482, 24694, 22929, 21189,
19478, 17799, 16155, 14548, 12980, 11455, 9975, 8540, 7154, 5818,
4533, 3300, 2122, 998, -70, -1082, -2037, -2935, -3776, -4561, -5288,
-5959,

6574, 7134, 7640, 8092, 8492, 8840, 9139, 9389, 9592, 9750, 9863, 9935,
9966, 9959, 9916, 9838, 9727, 9585, 9416, 9219, 8998, 8755, 8491,
8209, 7910, 7597, 7271, 6935, 6589, 6237, 5879, 5517,

5153, 4788, 4425, 4063, 3705, 3351, 3004, 2663, 2330, 2006, 1692,
1388, 1095, 814, 545, 288, 45, -185, -402, -605, -794, -970, -1131,
-1280, -1414, -1535, -1644, -1739, -1822, -1893, -1952, -2000,

2037, 2063, 2080, 2087, 2085, 2075, 2057, 2032, 2001, 1962, 1919, 1870,
1817, 1759, 1698, 1634, 1567, 1498, 1428, 1356, 1283, 1210, 1137,
1064, 991, 919, 848, 779, 711, 645, 581, 519,

459, 401, 347, 294, 244, 197, 153, 111, 72, 36, 2, -29, -57, -83,
-106, -127, -146, -163, -177, -189, -200, -208, -215, -221, -224,
-227, -228, -228, -227, -225, -222, -218,

213, 208, 202, 196, 190, 183, 176, 169, 161, 154, 147, 139, 132, 125,
117, 111, 104, 97, 91, 85, 79, 73, 68, 63, 58, 53, 49, 45, 41, 38, 35,
31,

29, 26, 24, 21, 19, 17, 16, 14, 13, 11, 10, 9, 8, 7, 7, 6, 5, 5, 4, 4,
3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1};



static long *layer1ScaleFactors = 0;   // 1.15 unsigned fixed-point

static layer2QuantClass l2qc3 = {3,5,YES};
static layer2QuantClass l2qc5 = {5,7,YES};
static layer2QuantClass l2qc7 = {7,3,NO};
static layer2QuantClass l2qc9 = {9,10,YES};
static layer2QuantClass l2qc15 = {15,4,NO};
static layer2QuantClass l2qc31 = {31,5,NO};
static layer2QuantClass l2qc63 = {63,6,NO};
static layer2QuantClass l2qc127 = {127,7,NO};
static layer2QuantClass l2qc255 = {255,8,NO};
static layer2QuantClass l2qc511 = {511,9,NO};
static layer2QuantClass l2qc1023 = {1023,10,NO};
static layer2QuantClass l2qc2047 = {2047,11,NO};
static layer2QuantClass l2qc4095 = {4095,12,NO};
static layer2QuantClass l2qc8191 = {8191,13,NO};
static layer2QuantClass l2qc16383 = {16383,14,NO};
static layer2QuantClass l2qc32767 = {32767,15,NO};
static layer2QuantClass l2qc65535 = {65535,16,NO};
layer2QuantClass *l2allocationA[] = {0,&l2qc3,&l2qc7,&l2qc15,
   &l2qc31,&l2qc63,&l2qc127,&l2qc255,&l2qc511,&l2qc1023,&l2qc2047,
   &l2qc4095,&l2qc8191,&l2qc16383,&l2qc32767,&l2qc65535};
layer2QuantClass *l2allocationB[] = {0,&l2qc3,&l2qc5,&l2qc7,&l2qc9,
   &l2qc15,&l2qc31,&l2qc63,&l2qc127,&l2qc255,&l2qc511,&l2qc1023,&l2qc2047,
   &l2qc4095,&l2qc8191,&l2qc65535};
layer2QuantClass *l2allocationC[] = {0,&l2qc3,&l2qc5,&l2qc7,
      &l2qc9,&l2qc15,&l2qc31,&l2qc65535};
layer2QuantClass *l2allocationD[] = {0,&l2qc3,&l2qc5,&l2qc65535};
layer2QuantClass *l2allocationE[] = {0,&l2qc3,&l2qc5,&l2qc9,
   &l2qc15,&l2qc31,&l2qc63,&l2qc127,&l2qc255,&l2qc511,&l2qc1023,&l2qc2047,
   &l2qc4095,&l2qc8191,&l2qc16383,&l2qc32767};
layer2QuantClass *l2allocationF[] = {0,&l2qc3,&l2qc5,&l2qc7,&l2qc9,
   &l2qc15,&l2qc31,&l2qc63,&l2qc127,&l2qc255,&l2qc511,&l2qc1023,&l2qc2047,
   &l2qc4095,&l2qc8191,&l2qc16383};

// 27 active subbands
// Mono requires 88 bits for allocation table
layer2BitAllocationTableEntry layer2AllocationB2a[32] = {
  { 4, l2allocationA },   { 4, l2allocationA },   { 4, l2allocationA },
  { 4, l2allocationB },   { 4, l2allocationB },   { 4, l2allocationB },
  { 4, l2allocationB },   { 4, l2allocationB },   { 4, l2allocationB },
  { 4, l2allocationB },   { 4, l2allocationB },   { 3, l2allocationC },
  { 3, l2allocationC },   { 3, l2allocationC },   { 3, l2allocationC },
  { 3, l2allocationC },   { 3, l2allocationC },   { 3, l2allocationC },
  { 3, l2allocationC },   { 3, l2allocationC },   { 3, l2allocationC },
  { 3, l2allocationC },   { 3, l2allocationC },   { 2, l2allocationD },
  { 2, l2allocationD },   { 2, l2allocationD },   { 2, l2allocationD },
  { 0,0},   { 0,0},   { 0,0},   { 0,0},   { 0,0}
};

// 30 active subbands
// Mono requires 94 bits for allocation table
// Used at highest bit rates
layer2BitAllocationTableEntry layer2AllocationB2b[32] = {
  { 4, l2allocationA },   { 4, l2allocationA },   { 4, l2allocationA },
  { 4, l2allocationB },   { 4, l2allocationB },   { 4, l2allocationB },
  { 4, l2allocationB },   { 4, l2allocationB },   { 4, l2allocationB },
  { 4, l2allocationB },   { 4, l2allocationB },   { 3, l2allocationC },
  { 3, l2allocationC },   { 3, l2allocationC },   { 3, l2allocationC },
  { 3, l2allocationC },   { 3, l2allocationC },   { 3, l2allocationC },
  { 3, l2allocationC },   { 3, l2allocationC },   { 3, l2allocationC },
  { 3, l2allocationC },   { 3, l2allocationC },   { 2, l2allocationD },
  { 2, l2allocationD },   { 2, l2allocationD },   { 2, l2allocationD },
  { 2, l2allocationD },   { 2, l2allocationD },   { 2, l2allocationD },
  { 0,0},   { 0,0}
};

// 7 active subbands
// Mono requires 26 bits for allocation table
// Used at lowest bit rates
layer2BitAllocationTableEntry layer2AllocationB2c[32] = {
  { 4, l2allocationE },   { 4, l2allocationE },   { 3, l2allocationE },
  { 3, l2allocationE },   { 3, l2allocationE },   { 3, l2allocationE },
  { 3, l2allocationE },   { 3, l2allocationE },
  {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},
  {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},
  {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},
};

// 11 active subbands
// Mono requires 38 bits for allocation table
// Used at lowest bit rates
layer2BitAllocationTableEntry layer2AllocationB2d[32] = {
  { 4, l2allocationE },   { 4, l2allocationE },   { 3, l2allocationE },
  { 3, l2allocationE },   { 3, l2allocationE },   { 3, l2allocationE },
  { 3, l2allocationE },   { 3, l2allocationE },   { 3, l2allocationE },
  { 3, l2allocationE },   { 3, l2allocationE },   { 3, l2allocationE },
  {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},
  {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},
};

// 30 active subbands
// Mono requires 75 bits for allocation table
// Used at low MPEG-2 sampling rates
layer2BitAllocationTableEntry layer2AllocationB1[32] = {
  { 4, l2allocationF },   { 4, l2allocationF },   { 4, l2allocationF },
  { 4, l2allocationF },   { 3, l2allocationE },   { 3, l2allocationE },
  { 3, l2allocationE },   { 3, l2allocationE },   { 3, l2allocationE },
  { 3, l2allocationE },   { 3, l2allocationE },   { 2, l2allocationE },
  { 2, l2allocationE },   { 2, l2allocationE },   { 2, l2allocationE },
  { 2, l2allocationE },   { 2, l2allocationE },   { 2, l2allocationE },
  { 2, l2allocationE },   { 2, l2allocationE },   { 2, l2allocationE },
  { 2, l2allocationE },   { 2, l2allocationE },   { 2, l2allocationE },
  { 2, l2allocationE },   { 2, l2allocationE },   { 2, l2allocationE },
  { 2, l2allocationE },   { 2, l2allocationE },   { 2, l2allocationE },
  {0,0},{0,0}
};



// subbandSamples input are 2.16

static void matrix(long *V, long *subbandSamples, int numSamples) 
{
int i;
static const double PI=3.14159265358979323846;
long *workR;
long workI[64]; // Imaginary part
long *pWorkR;
long *pWorkI;
char *next;
int size;
static long phaseShiftsR[32], phaseShiftsI[32]; // 1.14
static BOOL initializedPhaseShifts = NO;

int phaseShiftIndex, phaseShiftStep = 8;

int fftStep,n;
long *pcmR,*pcmI;

static const char order[] = {0,16,8,24,4,20,12,28,2,18,10,26,6,22,14,30,
                             1,17,9,25,5,21,13,29,3,19,11,27,7,23,15,31};

   for(i=numSamples;i<32;i++)
      subbandSamples[i]=0;

   workR=V; // Re-use V as work storage

   // The initialization step here precalculates the
   // two-point transforms (each two inputs generate four outputs)
   // I'm taking advantage of the fact that my inputs are all real
   pWorkR = workR; // 2.16
   pWorkI = workI; // 2.16
   next = order;
   for(n=0;n<16;n++) 
	{
      	long a = subbandSamples[*next++];
      	long b = subbandSamples[*next++];
      	*pWorkR++ = a+b;  *pWorkI++ = 0; 
     	*pWorkR++ = a;    *pWorkI++ = b; 
     	*pWorkR++ = a-b;  *pWorkI++ = 0; 
      	*pWorkR++ = a;    *pWorkI++ = -b;
   	}

   // This is a fast version of the transform in the ISO standard.
   // It's derived using the same principles as the FFT,
   // but it's NOT a Fourier Transform. 

   // For speed, precompute all of the phase shift values

  
   if (!initializedPhaseShifts) { // Initialize it only once
      for(i=0;i<32;i++) { // 1.14
         phaseShiftsR[i] = (long)(16384.0*cos(i*(PI/32.0)));
         phaseShiftsI[i] = (long)(16384.0*sin(i*(PI/32.0)));
      }
      initializedPhaseShifts = YES;
   }

   // In each iteration, I throw out one bit of accuracy
   // This gives me an extra bit of headroom to avoid overflow

   for(size=4; size<64; size <<= 1) 
	{
      	// Since the first phase shfit value is always 1,
     	 // I can save a few multiplies by duplicating the loop
      	for(n=0; n < 64; n += 2*size) 
		{
         	long tR = workR[n+size];
        	long tI;
         	workR[n+size] = (workR[n] - tR)>>1;
         	workR[n] = (workR[n] + tR)>>1;
         	tI = workI[n+size];
         	workI[n+size] = (workI[n] - tI)>>1;
         	workI[n] = (workI[n] + tI)>>1;
      		}
      	phaseShiftIndex = phaseShiftStep;
      	for(fftStep = 1; fftStep < size; fftStep++) 
		{
         	long phaseShiftR = phaseShiftsR[phaseShiftIndex];
         	long phaseShiftI = phaseShiftsI[phaseShiftIndex];
         	phaseShiftIndex += phaseShiftStep;
         	for(n=fftStep; n < 64; n += 2*size) 
			{
            		long tR = (phaseShiftR*workR[n+size] 
                     		- phaseShiftI*workI[n+size])>>14;
            		long tI = (phaseShiftR*workI[n+size] 
                     		+ phaseShiftI*workR[n+size])>>14;
            		workR[n+size] = (workR[n] - tR)>>1;
            		workI[n+size] = (workI[n] - tI)>>1;
            		workR[n] = (workR[n] + tR)>>1;
            		workI[n] = (workI[n] + tI)>>1;
         		}
      		}
      	phaseShiftStep /= 2;
   	}

   // Build final V values by massaging transform output
   {
      static long vShiftR[64], vShiftI[64]; // 1.13
      static BOOL initializedVshift = NO;
      int n;
  
      if (!initializedVshift) 
		{ // Initialize it only once
         	for(n=0;n<32;n++) 
			{ // 1.14
            		vShiftR[n] = (long)(16384.0*cos((32+n)*(PI/64.0)));
                	vShiftI[n] = (long)(16384.0*sin((32+n)*(PI/64.0)));
         		}
        	initializedVshift = YES;
      		}

      // Now build V values from the complex transform output
      pcmR = workR+33; // 6.12
      pcmI = workI+33; // 6.12
      V[16] = 0;    // V[16] is always 0
      for(n=1;n<32;n++) 
		{   // V is the real part, V is 6.9
         	V[n+16] = (vShiftR[n] * *pcmR++ - vShiftI[n] * *pcmI++)>>15;
      		}
      V[48] = (-workR[0])>>1;   // vShift[32] is always -1
      // Exploit symmetries in the result
      for(n=0;n<16;n++) 
		V[n] = -V[32-n];
      for(n=1;n<16;n++) 
		V[48+n] = V[48-n];
   }
}


// return 2.16 requantized and scaled value

long layer1Requant(long sample, int width, int scaleIndex) 

{
  long levels = (1<<width)-1;
  return (layer1ScaleFactors[scaleIndex]  *(((sample+sample+1 - levels)<<15)/levels))>>14;
}


// return 2.16 requantized and scaled value

long layer2Requant(long sample,layer2QuantClass *quantClass,int scaleIndex) 
{
   long levels = quantClass->levels;
   return (layer1ScaleFactors[scaleIndex]  *(((sample+sample+1 - levels)<<15)/levels)) >> 14;

}


@implementation MpegDecoder: AudioProcessor

-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(long) dataLength:(FILE*)file
{
long savedFilePos=0;
long byteSize=0;

// brute force approach, not very correct nor elegant

// This does not work is the bit rate or the sampling rate chnges
// in the middle of the file since it is onle based on the first
// mpeg frame header.

savedFilePos = ftell(file);

rewind(file);
while(!feof(file))
	{
	getc(file);
	byteSize++;
	}

clearerr(file);
fseek(file,savedFilePos,SEEK_SET);
clearerr(file);

return (long)((float)byteSize*(float)samplingRate*(float)16*(float)channels/(float)bitRate);
}

-(long) getSamples:(void*) outBuff forSize: (long)size 
{
short *tempBuff = outBuff;
long remaining = size;
   while(remaining > 0) 
	{
      	if(samplesRemaining == 0) 
		{ // buffer empty?
         	[self nextFrame];  // Get more data from MPEG stream
         	if(samplesRemaining == 0) // End of data?
            	return size-remaining;
      		}  
      	switch(channels) 
		{
      		case 1: // Mono, just copy left channel
         		while((samplesRemaining > 0) && (remaining > 0)) 
				{
                        	*tempBuff++ = *pcmSamples[0]++;
            			samplesRemaining--;
            			remaining--;
         			}
         		break;
      		case 2: // Stereo, copy both channels
         		while((samplesRemaining > 0) && (remaining > 0)) 
				{
                        	*tempBuff++ = *pcmSamples[0]++; // Left
                        	*tempBuff++ = *pcmSamples[1]++; // Right
            			samplesRemaining--;
            			remaining -= 2;
         			}
        		 break;
      		}
   	}
return size-remaining;
}

// Read and decompress next frame
-(void) nextFrame 
{
   if ([self parseHeader]) 
	{ // If no more headers
      	samplesRemaining = 0;
      	return;
   	}

   // Initialize for decoding
   pcmSamples[0] = sampleStorage[0];
   pcmSamples[1] = sampleStorage[1];

   switch(layer) 
	{
   	case 1: [self layer1Decode]; break;
        case 2: [self layer2Decode]; break;
        case 3: [self layer3Decode]; break;
   	}

   // Initialize for reading samples
   pcmSamples[0] = sampleStorage[0];
   pcmSamples[1] = sampleStorage[1];
}
 

// Move data to start of buffer and fill up rest
-(void) fillBuffer
{
int totalBufferSize;
int bufferSize;

// We ran off the end of the buffer?!
   
if (header > bufferStorage+sizeof(bufferStorage)) 
	{
      	[ERROR appendToError:@"Internal error; buffer exhausted!\n"];
      	buffer = header;
   	}

if (buffer > header) 
	{ // We skipped past the next header?!?!
      	[ERROR appendToError:@"Synchronization error; frame too big!\n"];
      	buffer = header;
   	}

// Avoid frequent small calls to ReadBytes()
if (buffer < (bufferStorage+512)) 
	return;

totalBufferSize = sizeof(bufferStorage);
bufferSize = bufferEnd - buffer;

memmove(bufferStorage,buffer, bufferSize);
header -= buffer - bufferStorage;
bufferEnd -= buffer - bufferStorage;
buffer = bufferStorage;
bufferEnd += [self readBytes:bufferEnd forSize: totalBufferSize - bufferSize];
/*if(bufferEnd != bufferStorage+sizeof(bufferStorage))
	[ERROR appendToError:@"ERROR !!!\n"];*/
}


-(void) resetBits 
{
   bitsRemaining = 8;
}


-(long) getBits:(int) numBits
{
long result;

   if(bitsRemaining == 0) 
	{ // If no bits in this byte ...
      	buffer++;           // ... move to the next
      	bitsRemaining = 8;
   	}

   if(bitsRemaining >= numBits) 
	{ // Can I fill it from this byte?
      	bitsRemaining -= numBits;
      	return (*buffer>>bitsRemaining)&masks[numBits];
   	}

   // Use up rest of this byte, then recurse to get more bits
   result = (*buffer & masks[bitsRemaining]) << (numBits - bitsRemaining);
   numBits -= bitsRemaining; // I don't need as many bits now
   bitsRemaining = 8;  // Move to next bit
   buffer++;
   return result | [self getBits:numBits];
}




// Parse header, return true if no more headers
-(BOOL) parseHeader
{
int bitrateIndex;
int samplingRateIndex;

   [self fillBuffer]; // Advance buffer
   if (bufferEnd - header < 4)
      return YES; // No more frames

   if((header[0] != 0xFF)||((header[1] & 0xF0) != 0xF0)) 
	{
      	[ERROR appendToError:@"Syncword not found.\n"];
	/*while( (header[0] != 0xFF) || ((header[1]&0xF0) != 0xF0) )
                        {
        		int slotLength = (layer == 1)?4:1;
                        header+=slotLength;
                        //headerSpacing++;
			}*/
      	return YES; // no more frames
   	}

   ID = (header[1] & 8)>>3; // 1 if MPEG-1, 0 if MPEG-2
   layer = -(header[1] >> 1) & 3; // Decode
   protection = (~header[1] & 1); // 0->CRC, 1->no CRC

   bitrateIndex = (header[2] & 0xF0)>>4;
   bitRate = bitRateTable[(int)ID][(int)layer][bitrateIndex] * 1000;
   
   samplingRateIndex = (header[2] & 0x0C)>>2;
   samplingRate = samplingRateTable[(int)ID][samplingRateIndex];

   padding = (header[2] & 0x02)>>1;   
   private = (header[2] & 0x01);

   mode = (header[3] & 0xC0) >> 6;
   modeExtension = (header[3] & 0x30)>>4;

   switch(mode) 
	{
   	case 0: // Stereo: all subbands
            channels = 2;
            bound = 32;
            break;
   	case 1: // Joint stereo: some subbands use intensity coding
            channels = 2;
            bound = (modeExtension + 1)<<2;
            break;
   	case 2: // Dual channel: two independent channels
            channels = 2;
            bound = 32;
            break;
   	case 3: // single channel
            channels = 1;
            bound = 0;
            break;
   	}

   copyright = (header[3] & 0x08);
   original = (header[3] & 0x04);
   emphasis = (header[3] & 0x03);

   buffer = header+4;
   if (protection) 
	buffer += 2; // Skip 2-byte CRC
   
if (bitRate == 0) 
	{ // Other bit rate
   
	if (headerSpacing) 
		{ // Already know header spacing
   		if (layer == 1) 
			{ // Layer 1 has 4-byte slots
      			header += headerSpacing * 4;
      			if(padding) header += 4;
   			} 
		else 
			{  // Layers 2 and 3 have 1-byte slots
      			header += headerSpacing;
      			if(padding) header += 1;
  	 		}
		} 
	else 
		{  // Need to search for next header
   		int slotLength = (layer == 1)?4:1;
   		headerSpacing = 1;
   		header+=slotLength;
   		while( (header[0] != 0xFF) || ((header[1]&0xF0) != 0xF0) ) 
			{
      			header+=slotLength;
      			headerSpacing++;
   			}
   		if (padding) 
			headerSpacing--;
		}
	} 

else if (layer==1) 
	{ // Layer 1 has 4-byte slots
	headerSpacing =   384 /  32  * bitRate   / samplingRate;
// slots/packet = samples/packet / bits/slot * bits/second / samples/second
   	header += headerSpacing*4;  // 4 bytes/slot
   	if(padding) 
		header += 4; // extra slot
	} 
else 
	{ // Layer 2 and 3 have 1-byte slots
   	headerSpacing = 1152 /  8  * bitRate / samplingRate;
// slots/packet = samples/packet / bits/slot * bits/second / samples/second 
   	header += headerSpacing;  // 1 byte/slot
   	if(padding) 
		header += 1; // Extra slot
	}

/*printf("Frame: \n ID:%f\n Layer:%f\n Protection%f\nSamplingRate:%f\nChanels: %f\nBitRate: %f\n,Padding: %f\n",(float)ID,(float)layer,(float)protection,(float)samplingRate,(float)channels,(float)bitRate,(float)padding);
printf("Private%f\nMode%f\nModeExt%f\nBound%f\ncopyright%f\nOriginal%f\nemphasis%f\nspacing%f\n",(float)private,(float)mode,(float)modeExtension,(float)bound,(float)copyright,(float)original,(float)emphasis,(float)headerSpacing);
  */ return NO; // Read header successfully
}


-(void) layer12Synthesis:(long**) Vloc :(long*) subbandSamples: (int) numSubbandSamples :(short*) pcmSamp
 {
   long *t = Vloc[15];
   static long D[512];
   static BOOL initializedD = NO;
   long *nextD=0;
   int i;
   int j;
   for(i=15;i>0;i--) // Shift V buffers over
      Vloc[i] = Vloc[i-1];
   Vloc[0] = t;

   // Convert subband samples into PCM samples in V[0]
   matrix(Vloc[0],subbandSamples,numSubbandSamples);

   // Rearrange synthesis window coefficients into a more
   // useful order, and scale them to 3.12
 
   if (!initializedD) 
	{
      	nextD = D;
      	for(j=0;j<32;j++)
        	for(i=0;i<16;i+=2) 
			{
            		*nextD++ = SynthesisWindowCoefficients[j+32*i]>>4;
            		*nextD++ = SynthesisWindowCoefficients[j+32*i+32]>>4;
         		}
      	initializedD = YES;
   	}

   // D is 3.12, V is 6.9, want 16 bit output
   nextD = D;
   for(j=0;j<32;j++) 
	{
      	long sample = 0; // 8.16
      	for(i=0;i<16;i+=2) 
		{
         	sample += (*nextD++ * Vloc[i][j]) >> 8;
         	sample += (*nextD++ * Vloc[i+1][j+32]) >> 8;
      		}
      	*pcmSamp++ = sample >> 1; // Output samples are 16 bit
   	}
}



-(void) layer1Decode 
{
   int allocation[2][32]; // One for each channel and subband
   int scaleFactor[2][32]; // One for each channel and subband
   long sbSamples[2][32]; // samples	
   int sb=0;
   int ch=0;
   int gr=0;
   [self resetBits];

   
if(channels == 1) 
	{
   	// Mono stores one allocation for each subband
   	for(sb=0;sb<32;sb++)
      		allocation[0][sb] = [self getBits:4];
	} 
else 
	{ // Stereo is slightly more complex
   	// Retrieve separate allocations for full stereo bands

   	for(sb=0;sb<bound;sb++) 
		{
      		allocation[0][sb] = [self getBits:4];
      		allocation[1][sb] = [self getBits:4];
   		}
   	// Retrieve shared allocation for intensity stereo bands
   	for(;sb<32;sb++) 
		{
      		allocation[0][sb] = [self getBits:4];
      		allocation[1][sb] = allocation[0][sb];
  		 }
	}
  

for(sb=0; sb<32; sb++)
      for(ch=0; ch<channels; ch++)
         if(allocation[ch][sb] != 0) 
		{
         	scaleFactor[ch][sb] = [self getBits:6];
         	}
   
for(gr=0;gr<12;gr++) 
	{ // Read 12 groups of samples
      	if(channels == 1) 
		{         
		for(sb=0;sb<32;sb++) // Read a group of 32 samples
   			if(!allocation[0][sb]) // No bits?
      				sbSamples[0][sb] = 0;
   			else 
				{
      				int width = allocation[0][sb]+1;
      				long s = [self getBits:width];
      				// Requantize and Scale this sample
      				sbSamples[0][sb] = layer1Requant(s, width,scaleFactor[0][sb]);
   				}
		[self layer12Synthesis:V[0] :sbSamples[0]:32:pcmSamples[0]];
		pcmSamples[0] += 32;
		samplesRemaining += 32;
      		} 
	else 
		{ // Stereo
         
		// Retrieve samples for full stereo subbands
   		for(sb=0;sb<bound;sb++)
      			for(ch=0;ch<2;ch++)
         			if(!allocation[ch][sb])
            				sbSamples[ch][sb] = 0;
         			else 
					{
            				int width = allocation[ch][sb]+1;
            				long s = [self getBits:width];
            				// Requantize and Scale this sample
            				sbSamples[ch][sb] = layer1Requant(s, width,scaleFactor[ch][sb]);
         				}
		}

  	// Retrieve shared samples for intensity stereo subbands
   	for(sb=0;sb<bound;sb++) 
		{
      		if(!allocation[0][sb])
         		sbSamples[0][sb] = 0;
      		else 
			{
         		int width = allocation[0][sb]+1;
         		long s = [self getBits:width];
         		// Requantize and Scale this sample for each channel
         		sbSamples[0][sb] = layer1Requant(s, width,scaleFactor[0][sb]);
         		sbSamples[1][sb] = layer1Requant(s, width,scaleFactor[1][sb]);
      			}
   		}


	// Now, reconstruct each channel
	for(ch=0;ch<channels;ch++) 
		{
   		[self layer12Synthesis:V[ch]:sbSamples[ch]:32:pcmSamples[ch]];
   		pcmSamples[ch] += 32;
		}
	samplesRemaining += 32;
      }
   
}



-(void) layer2Decode
{
int allocation[2][32]; // One for each channel and subband
long bitRatePerChannel;
int sblimit;

int scaleFactor[3][2][32]; // One for each channel and subband
long sbSamples[3][2][32]; // Three sets of subband samples

int scaleFactorSelection[2][32];

layer2BitAllocationTableEntry *allocationMap;

int sb;
int ch,sf,gr;
[self resetBits];

   
// Select which allocation map to use
bitRatePerChannel = bitRate/channels;

if(ID==0) // Use MPEG-2 allocation map
      allocationMap = layer2AllocationB1;
else if(bitRatePerChannel <= 48000) 
	{
   	if(samplingRate == 32000) 
		allocationMap = layer2AllocationB2d;
   	else 
		allocationMap = layer2AllocationB2c;
	} 
else if (bitRatePerChannel < 96000)
   allocationMap = layer2AllocationB2a;
else if (samplingRate == 48000)
   allocationMap = layer2AllocationB2a;
else
   allocationMap = layer2AllocationB2b;

// Note: frame header sets bound to 0 for single-channel,
// so the following works correctly for both stereo and mono
sblimit=0; // One past highest subband with non-empty allocation

 // Retrieve separate allocations for full stereo bands
   for(sb=0;sb<bound;sb++) 
	{
      	if(allocationMap[sb].numberBits) 
		{
         	allocation[0][sb] = [self getBits:allocationMap[sb].numberBits];
         	allocation[1][sb] = [self getBits:allocationMap[sb].numberBits];
         	if(  (allocation[0][sb] || allocation[1][sb]) &&(sb >= sblimit) )
            	sblimit=sb+1;
      		} 
	else 
		{
         	allocation[0][sb] = 0;
         	allocation[1][sb] = 0;
      		}
   	}


// Retrieve shared allocation for intensity stereo bands
   for(sb=bound;sb<32;sb++) 
	{
      	if(allocationMap[sb].numberBits) 
		{
         	allocation[0][sb] = [self getBits:allocationMap[sb].numberBits];
         	if(allocation[0][sb] && (sb >= sblimit))
            		sblimit=sb+1;
      		} 
	else
         	allocation[0][sb] = 0;
      allocation[1][sb] = allocation[0][sb];
   	}


// Retrieve scale factor selection information
   for(sb=0; sb<sblimit; sb++)
      for(ch=0; ch<channels; ch++)
         if(allocation[ch][sb] != 0)
            scaleFactorSelection[ch][sb] = [self getBits:2];

   // Read scale factors, using scaleFactorSelection to
   // determine which scale factors apply to more than one group
   for(sb=0; sb<sblimit; sb++)
      for(ch=0; ch<channels; ch++)
         if(allocation[ch][sb] != 0)
 		{
            switch(scaleFactorSelection[ch][sb]) 
		{
            	case 0: // Three scale factors
               		scaleFactor[0][ch][sb] = [self getBits:6];
               		scaleFactor[1][ch][sb] = [self getBits:6];
               		scaleFactor[2][ch][sb] = [self getBits:6];
               		break;
            	case 1: // One for first two-thirds, one for last third
                	scaleFactor[0][ch][sb] = [self getBits:6];
               		scaleFactor[1][ch][sb] = scaleFactor[0][ch][sb];
                	scaleFactor[2][ch][sb] = [self getBits:6];
              		 break;
            	case 2: // One for all three
                	scaleFactor[0][ch][sb] = [self getBits:6];
               		scaleFactor[1][ch][sb] = scaleFactor[0][ch][sb];
               		scaleFactor[2][ch][sb] = scaleFactor[0][ch][sb];
               		break;
            case 3: // One for first third, one for last two-thirds
               		scaleFactor[0][ch][sb] = [self getBits:6];
               		scaleFactor[1][ch][sb] = [self getBits:6];
               		scaleFactor[2][ch][sb] = scaleFactor[1][ch][sb];
               break;
            }
         }

   for(sf=0;sf<3;sf++) 
	{ // Diff't scale factors for each 1/3
   	
      	for(gr=0;gr<4;gr++) 
		{ // 4 groups of samples in each 1/3
		for(sb=0;sb<sblimit;sb++) 
			{ // Read 3 sets of 32 subband samples
   			for(ch=0;ch<channels;ch++) 
				{
                       	 	layer2QuantClass *quantClass;
      				// If this is an intensity stereo band, just copy samples over
     		 		if((sb>=bound) && (ch == 1)) 
					{
         				sbSamples[0][1][sb] = sbSamples[0][0][sb];
         				sbSamples[1][1][sb] = sbSamples[1][0][sb];
         				sbSamples[2][1][sb] = sbSamples[2][0][sb];
         				continue;
      					}
      				quantClass= allocationMap[sb].quantClasses ? 
					allocationMap[sb].quantClasses[ allocation[ch][sb] ] : 0 ;

      				if(!allocation[ch][sb]) 
					{ // No bits, store zero for each set
         				sbSamples[0][ch][sb] = 0;
         				sbSamples[1][ch][sb] = 0;
         				sbSamples[2][ch][sb] = 0;
      					} 
				else if (quantClass->grouping) 
					{ // Grouped samples
         				long s = [self getBits:quantClass->bits]; // Get group
         				// Separate out by computing successive remainders
         				sbSamples[0][ch][sb] = layer2Requant(s % quantClass->levels,quantClass,scaleFactor[sf][ch][sb]);
         				s /= quantClass->levels;
         				sbSamples[1][ch][sb] = layer2Requant(s % quantClass->levels,quantClass,scaleFactor[sf][ch][sb]);
         				s /= quantClass->levels;
         				sbSamples[2][ch][sb] = layer2Requant(s % quantClass->levels,quantClass,scaleFactor[sf][ch][sb]);
      					} 
				else 
					{ // Ungrouped samples
         				int width = quantClass->bits;
         				long s = [self getBits:width]; // Get 1st sample
         				sbSamples[0][ch][sb] = layer2Requant(s,quantClass,scaleFactor[sf][ch][sb]);
         				s = [self getBits:width]; // Get 2nd sample
         				sbSamples[1][ch][sb] = layer2Requant(s,quantClass,scaleFactor[sf][ch][sb]);
         				s = [self getBits:width]; // Get 3rd sample
         				sbSamples[2][ch][sb] = layer2Requant(s,quantClass,scaleFactor[sf][ch][sb]);
      					}
   				}
			}

			// Now, feed three sets of subband samples into synthesis engine
			for(ch=0;ch < channels;ch++) 
				{
                        	[self layer12Synthesis:V[ch]:sbSamples[0][ch]:sblimit:pcmSamples[ch]];
   				pcmSamples[ch] += 32;
                                [self layer12Synthesis:V[ch]:sbSamples[1][ch]:sblimit:pcmSamples[ch]];
   				pcmSamples[ch] += 32;
                                [self layer12Synthesis:V[ch]:sbSamples[2][ch]:sblimit:pcmSamples[ch]];
   				pcmSamples[ch] += 32;
				}	
			samplesRemaining += 96;
      			}
   		}
}

-(void) layer3Decode
{
   [ERROR appendToError:@"MPEG Layer 3 decompression not supportes\n"];
}


-initWithPrevious:prev
{
int ch,i,j;
[super initWithPrevious:prev];


samplesRemaining = 0;

buffer = bufferStorage + sizeof(bufferStorage);
header = bufferEnd = buffer;
headerSpacing = 0; // Unknown

for(ch=0;ch<2;ch++) 
	{    // V is stored in object
 	for(i=0;i<16;i++) 
		{
    		V[ch][i] = malloc(sizeof(long)*64);
    		for(j=0;j<64;j++)
       			V[ch][i][j] = 0;
 		}
	}

if(!layer1ScaleFactors) 
	{
 	layer1ScaleFactors = malloc(sizeof(long)*63);
 	for(i=0;i<63;i++) 
		{
    		layer1ScaleFactors[i] = (long)(32767.0 * pow(2.0, 1.0 - i/3.0));
 		}
	}
 [self nextFrame]; // Read first frame
 //printf("Encoding: MPEG-%f", (float)((ID==0)?2:1));
 //printf(" Layer %f\n",(float)(layer));

 //printf("Sampling Rate: %f\n", (float)samplingRate);
 switch(mode) 
	{
 	case 0: 
		//printf("Mode: Stereo\n"); 
		break;
 	case 1: 
		//printf("Mode: Joint Stereo\n"); 
		break;
 	case 2: 
		//printf("Mode: Dual Channel\n"); 
		break;
 	case 3: 
		//printf("Mode: Single Channel\n"); 
		break;
 	}
 //printf("Bitrate: %f\n",(float)bitRate);
 switch(emphasis) 
	{
 	case 0:  
		//printf("Emphasis: none\n"); 
		break;
 	case 1: 
		//printf("Emphasis: 50/15\n"); 
		break;
 	case 2:  
		//printf("Emphasis: reserved\n"); 
		break;
 	case 3: 
		//printf("Emphasis: ITU J.17\n"); 
		break;
 	}
 //printf("Approximate Compression Ratio: %5.1f:1\n", samplingRate*16.0*channels/bitRate);



return self;
}

// Destructor
-(void) dealloc 
{
int ch;
int i;
  
for(ch=0;ch<2;ch++)
   for(i=0;i<16;i++)
      free(V[ch][i]);
free (layer1ScaleFactors);
layer1ScaleFactors = 0;
}

-(void) minMaxSamplingRate:(long *)min: (long *)max: (long *)preferred 
{
   *min=*max=*preferred=samplingRate;
}

-(void) minMaxChannels:(long*)min:(long*)max:(long *)preferred  
{
   *min=*max=*preferred=channels;
}

@end
