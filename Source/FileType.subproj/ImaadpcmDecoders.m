/** imaadpcmDecoders.m
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

#import "SoundFormats.h"
#import "ImaadpcmDecoders.h"

#import "ErrorHandler.h"

static const int indexAdjustTable[16] = {
   -1, -1, -1, -1,  // +0 - +3, decrease the step size
    2, 4, 6, 8,     // +4 - +7, increase the step size
   -1, -1, -1, -1,  // -0 - -3, decrease the step size
    2, 4, 6, 8,     // -4 - -7, increase the step size
};
static const int stepSizeTable[89] = {
   7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34,
   37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143,
   157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494,
   544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552,
   1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026,
   4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442,
   11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623,
   27086, 29794, 32767
};


short imaAdpcmDecode(unsigned char deltaCode, imaState *state) 
{
   // Get the current step size
   int step = stepSizeTable[state->index];

   // Construct the difference by scaling the current step size
   // This is approximately: difference = (deltaCode+.5)*step/4
   int difference = step>>3;
   if ( deltaCode & 1 ) difference += step>>2;
   if ( deltaCode & 2 ) difference += step>>1;
   if ( deltaCode & 4 ) difference += step;
   if ( deltaCode & 8 ) difference = -difference;

   // Build the new sample
   state->previousValue += difference;
   if (state->previousValue > 32767) state->previousValue = 32767;
   else if (state->previousValue < -32768) state->previousValue = -32768;

   // Update the step for the next sample
   state->index += indexAdjustTable[deltaCode];
   if (state->index < 0) state->index = 0;
   else if (state->index > 88) state->index = 88;

   return state->previousValue;
}
unsigned char imaAdpcmEncode(short sample, imaState *state) {
   int diff = sample - state->previousValue;
   int step = stepSizeTable[state->index];
   int deltaCode = 0;

   // Set sign bit
   if (diff < 0) { deltaCode = 8; diff = -diff; }

   // This is essentially deltaCode = (diff<<2)/step,
   // except the roundoff is handled differently.
   if ( diff >= step ) {  deltaCode |= 4;  diff -= step;  }
   step >>= 1;
   if ( diff >= step ) {  deltaCode |= 2;  diff -= step;  }
   step >>= 1;
   if ( diff >= step ) {  deltaCode |= 1;  diff -= step;  }

   imaAdpcmDecode(deltaCode,state);  // update state
   return deltaCode;
}

@implementation ImaAdpcmMsDecoder


- initWithPrevious:prev packetLength: (int)packetLength channels :(int)chan
{
[super initWithPrevious:prev];

channels = chan;
samplesPerPacket = packetLength;
bytesPerPacket = (samplesPerPacket + 7 )/2 * channels;
packet = malloc(sizeof( unsigned char)*(bytesPerPacket));
samples[1] = samples[0] = 0;

while (chan-- > 0)
      samples[chan] = malloc(sizeof( short)*samplesPerPacket);
   samplesRemaining = 0;

return self;
}

-(void)dealloc
{
   if (samples[0]) free( samples[0]);
   if (samples[1]) free( samples[1]);
   if (packet) free( packet);
};


-(long) nextPacket
{
   // Pull in the packet and check the header
   long bytesRead = [self readBytes:packet forSize:bytesPerPacket];
   unsigned char *bytePtr;
   imaState state[2];  // One decompressor state for each channel
   int ch;
   long remaining ;


   if (bytesRead < bytesPerPacket) 
	 return 0;

   bytePtr = packet;

   // Reset the decompressor

   // Read the four-byte header for each channel
   for(ch=0;ch < channels; ch++) 
	{
      	state[ch].previousValue =  (signed char)(bytePtr[1])*0x100 + (signed char)(bytePtr[0]);

      	if (bytePtr[2] > 88)
         	[ERROR appendToError:@"IMA ADPCM Format Error (bad index value)\n"];
      	else
         	state[ch].index = bytePtr[2];
      	if (bytePtr[3])
         	[ERROR appendToError:@"IMA ADPCM Format Error (synchronization error)\n"];
      	bytePtr+=4; // Skip this header

      	samplePtr[ch] = samples[ch];
      	// Decode one sample for the header
      	*samplePtr[ch]++ = state[ch].previousValue;
   	}

   // Decompress nybbles
   remaining = samplesPerPacket-1;

   while (remaining>0) 
	{
   	int i;
      	
	remaining-=8;

      	
      	// Decode 8 left samples
      	for (i=0;i<4;i++) 
		{
         	unsigned char b = *bytePtr++;
         	*samplePtr[0]++ = imaAdpcmDecode(b & 0xF,&(state[0]));
         	*samplePtr[0]++ = imaAdpcmDecode((b>>4) & 0xF,&(state[0]));
      		}
      	if (channels < 2)
         	continue; // If mono, skip rest of loop
      	// Decode 8 right samples
      	for (i=0;i<4;i++) 
		{
         	unsigned char b = *bytePtr++;
         	*samplePtr[1]++ = imaAdpcmDecode(b & 0xF,&(state[1]));
         	*samplePtr[1]++ = imaAdpcmDecode((b>>4) & 0xF,&(state[1]));
      		}
   	}
   return samplesPerPacket;
}

-(long) getSamples:(void *)outBuff forSize: (long) len 
{
   long wanted = len;
   short *buffer = outBuff;
   while (wanted > 0) 
	{ // Still want data?
      	if (samplesRemaining == 0) 
		{ // Need to read more from disk?
         	samplesRemaining = [self nextPacket];
         	if (samplesRemaining == 0) 
			return len - wanted;
         	samplePtr[0] = samples[0];
         	samplePtr[1] = samples[1];
      		}
      switch(channels) 
		{ // Copy data into outBuff
      case 1: // Mono: Just copy left channel data
         while((samplesRemaining > 0) && (wanted > 0)) 
		{
            	*buffer++ = *samplePtr[0]++;
            	samplesRemaining--;
            	wanted--;
         	}
         break;
      case 2: // Stereo: Interleave samples
         while((samplesRemaining > 0) && (wanted > 0)) 
		{
            	*buffer++ = *samplePtr[0]++; // left
            	*buffer++ = *samplePtr[1]++; // right
            	samplesRemaining--;
            	wanted -= 2;
         	}
         break;
      default: return 0;
      }
   }
   return (len - wanted)*4;
}


-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(short) inputFormat
{
return SND_FORMAT_IMAADPCM_APPL;
}

@end


@implementation ImaAdpcmAppleDecoder

- initWithPrevious:prev channels: (int)chan
 {
[super initWithPrevious:prev];
   samplesRemaining = 0;
   state[0].previousValue = 0;
   state[0].index = 0;
   state[1] = state[0];
   channels = chan;

return self;
}

-(long)  nextPacket:(short *)sampleBuffer :(imaState *)theState 
{
   unsigned char packet[34];
   // Pull in the packet and check the header
   long  bytesRead = [self readBytes:packet forSize: 34];
   short lastSample;
   int i;

   if (bytesRead < 34) 
	return 0;

   // Check the decompressor state
   theState->index = packet[1] & 0x7F;
   if (theState->index > 88) 
	{
      	[ERROR appendToError:@"Synchronization error.\n"];
      	return 0;
   	}

   // Recover upper nine bits of last sample
   lastSample = ((signed char)(packet[0])*0x100 +  (signed char)(packet[1])) & 0xFF80;

   // If ours doesn't match, reset to the value in the file
   if ((theState->previousValue & 0xFF80) != lastSample)
     theState->previousValue = lastSample;

   // Decompress nybbles
   for(i=0; i<32; i++) {
   	*sampleBuffer++ = imaAdpcmDecode(packet[i+2] & 0xF, theState);
   	*sampleBuffer++ = imaAdpcmDecode((packet[i+2]>>4) & 0xF, theState);
   }
   return 64;
}


-(long) getSamples:(void *)outBuff forSize:(long) wanted
{
   long  remaining = wanted/2;
   int i;
   short* buffer = outBuff;
   while (remaining > 0) 
	{
      	if (samplesRemaining == 0) 
		{
         for(i=0; i<channels; i++) 
		{
            	samplesRemaining = [self nextPacket:samples[i]:&(state[i])];
            	if (samplesRemaining == 0)
			return wanted-remaining;
            	samplePtr[i] = samples[i];
         	}
      	}
      switch(channels) 
	{
      	case 1:
         	while((samplesRemaining > 0) && (remaining > 0)) 
			{
                	*buffer++ = *samplePtr[0]++;
            		samplesRemaining--;
            		remaining--;
         		}
         break;
      	case 2:
         	while((samplesRemaining > 0) && (remaining > 0)) 
			{
                	*buffer++ = *samplePtr[0]++; // Left
                	*buffer++ = *samplePtr[1]++; // Right
            		samplesRemaining--;
            		remaining -= 2;
         		}
         break;
      	}
   }
   return (wanted - remaining)*4;
}


-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(short) inputFormat
{
return SND_FORMAT_IMAADPCM_APPL;
}
@end
