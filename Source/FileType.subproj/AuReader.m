/** auReader.m
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

#import "AuReader.h"
#import <stdio.h>

#import "FeedForwardDecoder.h"
#import "G711Decoders.h"
#import "G721Decoder.h"
#import "G723Decoders.h"

#import "ErrorHandler.h"

BOOL isAuFile(FILE *file) 
{
   long magic;
   rewind(file);  // Seek to beginning
   fread(&magic,1,4,file);

   magic = NSSwapBigLongToHost(magic);

   return (magic == DEC_INV_MAGIC || 
	   magic == SUN_INV_MAGIC ||
           magic == SUN_MAGIC || 	// Should be `.snd'
           magic == DEC_MAGIC); 	
}


@implementation AuReader


-initFromFile:(FILE *)theFile
{
[super initFromFile:theFile];

headerRead = NO;
needToSwap = NO;
return self;
}

- (void) dealloc
    {
    if(decoder)
	[decoder release];
    }

-(long) dataLength
{
[self readHeader];
return originalDataLength*formatSampleSize([self outputFormat])/formatSampleSize([self inputFormat]);
}

-(short) outputFormat
{
[self readHeader];
return [decoder outputFormat];
}

-(short) inputFormat;
{
[self readHeader];
return inputFormat;
}


- (long) getSamples:(void*)samplesBuffer forSize:(long)size
{
return [decoder getSamples:samplesBuffer forSize:size];
}

- (long) readBytes:(void*)bytesBuffer forSize:(long)size
{
   int lengthRead;

   if (size > dataLength) 
	size = dataLength;

   lengthRead = fread(bytesBuffer,1,size,file);

   if (lengthRead != size) 
   {
       char tempStr[80];
       sprintf(tempStr,"Read error: wanted %f, got %f\n",(float)size, (float)lengthRead);
       [ERROR appendToError:[NSString stringWithCString:tempStr]];
      // fclose(file);
      return 0;
    }

   dataLength -= lengthRead;

   if (needToSwap) {
           short	*sdata;
           signed char	*scdata;
           long int	*lidata;
           float	*fdata;
           register	int	i;

         switch (inputFormat) {
            case SND_FORMAT_LINEAR_8:
               scdata = bytesBuffer;
            	for (i = 0; i < lengthRead; i++) {
                  scdata[i] ^= 128;
               }
               break;
            case SND_FORMAT_LINEAR_16:
            	sdata = (short *)bytesBuffer;
            	for (i = 0; i < lengthRead/2; i++) {
                  sdata[i] = NSSwapShort(sdata[i]);
               }
               break;
            case SND_FORMAT_LINEAR_32:
            	lidata = (long int *)bytesBuffer;
            	for (i = 0; i < lengthRead/4; i++) {
                  lidata[i] = NSSwapInt(lidata[i]);
               }
               break;
            case SND_FORMAT_FLOAT:
            	fdata = (float *)bytesBuffer;
            	for (i = 0; i < lengthRead/4; i++) {
                /* This does not pass on Mac OS X Server */
                                //fdata[i] = NSSwapFloat((NSSwappedFloat)fdata[i]);

                                /* Trying this instead */

                        fdata[i] = NSConvertSwappedFloatToHost(NSSwapFloat(NSConvertHostFloatToSwapped(fdata[i])));
               }
               break;
         }
      }



   return lengthRead;
}


-(void) readHeader 
{
   unsigned long	(*readlongFn)();
   long magic;
   long headerLength;

   if (headerRead) return;
   headerRead = YES;

  
   rewind(file);  // Seek to beginning
   fread(&magic,1,4,file);

   magic = NSSwapBigLongToHost(magic);

   if(magic == DEC_INV_MAGIC || magic == SUN_INV_MAGIC)
        needToSwap = YES;
   else 
     {
     if ((magic != SUN_MAGIC) && (magic != DEC_MAGIC)) 
	{
        [ERROR appendToError:@"Sun/NeXT/DEC header doesn't start SND.\n"];
        //printf("Try using sndconvert for raw data -- \n");
        //printf("assume 8000 Hz sampling rate.\n");
        return;
	}
     }

   if (needToSwap)
         readlongFn = &nx_rllong;
   else
         readlongFn = &nx_rblong;


   headerLength = (*readlongFn)(file);

   if (headerLength < SUN_HDRSIZE) {
         [ERROR appendToError:@"Sun/NeXT header size too small"];
         return;
   }

   dataLength = (*readlongFn)(file);
   originalDataLength = dataLength;
   inputFormat = (*readlongFn)(file);
   headerRate = (*readlongFn)(file);
   headerChannels = (*readlongFn)(file);
   skipBytes(file,headerLength - 24); // Junk rest of header

   // Create an appropriate decompression object
   switch(inputFormat) {
   case 1: // ITU G.711 mu-Law
      decoder = [[FeedForwardDecoder alloc] initWithPrevious:self];
      //decoder = [[uLawDecoder alloc] initWithPrevious:self];	// this one will convert it to 16 bits linear !
      break;
   case 2: // 8-bit linear
      decoder = [[FeedForwardDecoder alloc] initWithPrevious:self];
      break;
   case 3: // 16-bit linear
      decoder = [[FeedForwardDecoder alloc] initWithPrevious:self];
      break;
   case 23: // 4-bit ADPCM G721
        decoder = [[G721Decoder alloc] initWithPrevious:self];
        break;
   case 25: // 3-bit ADPCM G723.3
        decoder = [[G723_24Decoder alloc] initWithPrevious:self];
        break;
   case 26: // 5-bit ADPCM G723.5
        decoder = [[G723_24Decoder alloc] initWithPrevious:self];
        break;
   case 27: // 8-bit A_Law G711
      decoder = [[ALawDecoder alloc] initWithPrevious:self];
      break;
   default:
	{
	char tempStr[80];
      sprintf(tempStr,"AU Format %d not supported",inputFormat);
      [ERROR appendToError:[NSString stringWithCString:tempStr]];
	}
      return;
   }
}



- (void) minMaxSamplingRate:(long*) min :(long*) max: (long*) preferred
{
[self readHeader];
*min = *max = *preferred = headerRate;
}

- (void) minMaxChannels:(long*) min :(long*) max: (long*) preferred
{
[self readHeader];

*min = *max = *preferred = headerChannels;
}

@end


