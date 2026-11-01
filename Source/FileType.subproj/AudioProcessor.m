/** audioProcessor.m
Copyright (c) 1998 Jerome Genest.  All rights reserved.
jgenest@gel.ulaval.ca

This source code was insprired from and thus contains parts from:

-C++ framework (in "A Programmer©s guide to sound, Addison-Wesley)
 by Tim Kientzle Copyright 1997.  All rights reserved.

-Original Resound file reader utilities by Malcom Crawford and Sean Luke, all rights reserved

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

#import "AudioProcessor.h"
#import "ErrorHandler.h"

/* -------------------------------------------------------------------- */
/* Utilities  paralleling those in misc.c*/

/* -------------------------------------------------------------------- */
unsigned short nx_rlshort(FILE *stream)
{
        unsigned short	s;
   fread(&s,sizeof(short),1,stream);
   s = NSSwapLittleShortToHost(s);
   return s;
}

/* -------------------------------------------------------------------- */
unsigned short nx_rbshort(FILE *stream)
{
        unsigned short	s;
   fread(&s,sizeof(short),1,stream);
   s = NSSwapBigShortToHost(s);
   return s;
}

/* -------------------------------------------------------------------- */
unsigned long nx_rllong(FILE *stream)
{
        unsigned long	l;
   fread(&l,sizeof(long),1,stream);
   l = NSSwapLittleLongToHost(l);
   return l;
}

/* -------------------------------------------------------------------- */
unsigned long nx_rblong(FILE *stream)
{
        unsigned long	l;
   fread(&l,sizeof(long),1,stream);
   l = NSSwapBigLongToHost(l);
   return l;
}

void skipBytes(FILE *in, int size) {
   while (size-- > 0)
      getc(in);
}

long readIntLsb(FILE *in, int size) 
{
long l;

   if (size <= 0) return 0;
   l = (long) (getc(in) & 255);
   l |= readIntLsb(in,size-1)<<8;
   return l;
}


@implementation AudioProcessor

-init
{
previous = 0;
next = 0;
samplingRate = 0;  
samplingRateFrozen = NO;
sampleSize = 0;
channels = 0;      
channelsFrozen = NO;
return self;
}

-initWithPrevious:prev
{
previous = prev;
next = 0;
[previous setNext:self];
samplingRate = 0;
samplingRateFrozen = NO;
sampleSize = 0;
channels = 0;
channelsFrozen = NO;
return self;
}

-(short) outputFormat
{
return outputFormat;
}

-(short) inputFormat;
{
return inputFormat;
}

- (id) previous;
{ 
return previous;
}

- (id) next
{ 
return next;
}

-(void) setNext:theNext
{
next = theNext;
}

- (long) getSamples:(void*)samplesBuffer forSize:(long)size
{
return 0;
}

- (long) readBytes:(void*)bytesBuffer forSize:(long)size
{
return [[self previous] readBytes:bytesBuffer forSize:size];
}

- (double) samplingRate
{
   if (!samplingRateFrozen)  	// Not frozen?
   [self negotiateSamplingRate]; // Go figure it out
   return samplingRate; 	// Return it
}

- (void) setSamplingRate:(long) s // Set the sampling rate
{    
  if (samplingRateFrozen) 
   {
      [ERROR appendToError:@"Sampling rate can©t be changed\n"];
      return;
   }
   samplingRate = s;
};

- (int) channels
{
   if (!channelsFrozen) 
	[self negotiateChannels];
   return channels;
}

-(void) setChannels:(int) ch
{
   if (channelsFrozen) 
  {
      [ERROR appendToError:@"Number of channels can©t be changed\n"];
      return;
   }
   channels = ch;
}

-(void) negotiateSamplingRate 
{
   if ([self next]) // Are we the leftmost?
      [[self next] negotiateSamplingRate]; // No, keep goin
   else { // Yes, we are
      long min = 8000, max = 44100, preferred = 44100;
      [self minMaxSamplingRate:&min:&max:&preferred]; // Get preferred values
      if (min > max) { // Check for rediculous answers
     	 [ERROR appendToError:@"Sampling rate could not be negociated\n"];
         return;
      }
      [self setSamplingRateRecursive:preferred]; // Set them everywhere
   }
}
-(void) minMaxSamplingRate:(long *)min: (long *)max: (long *)preferred 
{
   if ([self previous])
	 [[self previous] minMaxSamplingRate:min:max:preferred];
   if (samplingRate) *preferred = samplingRate;
   if (*preferred < *min) *preferred = *min;
   if (*preferred > *max) *preferred = *max;
}

-(void) setSamplingRateRecursive:(long) s 
{
   if ([self previous])  // Set towards the right first
      [[self previous] setSamplingRateRecursive:s];
   [self setSamplingRate:s]; // Set it
   samplingRateFrozen = NO; // Yes, we've negotiated
}

-(void) negotiateChannels 
{
   if ([self next])
      [[self next] negotiateChannels];
   else {
      long min=1, max=2, preferred=1; // Some reasonable default
      [self minMaxChannels:&min:&max:&preferred];
      if (min > max) 
      {
         [ERROR appendToError:@"Number of channels could not be negociated\n"];
         exit(1);
      }
      [self setChannelsRecursive:preferred];
   }
}

-(void) minMaxChannels:(long*)min:(long*)max:(long *)preferred 
{
   if ([self previous])  
	[ [self previous] minMaxChannels:min:max:preferred];
   if (channels) *preferred = channels;
   if (*preferred < *min) *preferred = *min;
   if (*preferred > *max) *preferred = *max;
}

-(void) setChannelsRecursive:(int) ch 
{
   if ([self previous]) [[self previous] setChannelsRecursive:ch];
   [self setChannels:ch];
   channelsFrozen = YES;
}

@end