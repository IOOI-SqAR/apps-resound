/** aiffReader.m 
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
to this material without the specific, prior written permission of the author
 
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



 
#import "AiffReader.h"
#import "FeedForwardDecoder.h"
#import "ImaadpcmDecoders.h"

#import "ErrorHandler.h"

BOOL isAiffFile(FILE *file) 
{
unsigned long form;
unsigned long type;

   rewind(file); // Seek to beginning of file
   form = nx_rblong(file);
   if (form != CHUNKNAME('F','O','R','M'))
      return NO; // Not IFF file
   skipBytes(file,4);  // Skip chunk size
   type = nx_rblong(file);
   if (type == CHUNKNAME('A','I','F','F'))
      return YES;
   if (type == CHUNKNAME('A','I','F','C'))
      return YES;
   return NO; // IFF file, but not AIFF or AIFF-C file
}

@implementation AiffReader

-initFromFile:(FILE*)theFile
{
[super initFromFile:theFile];

formatData = 0;
formatDataLength = 0;

currentChunk = -1; // Empty the stack
[self nextChunk];

// Ensure first chunk is a FORM/AIFF container
if (  (currentChunk != 0)
      || (chunk[0].type != CHUNKNAME('F','O','R','M'))
  || (chunk[0].isContainer != YES) 
  || (  (chunk[0].containerType != CHUNKNAME('A','I','F','F'))
      &&(chunk[0].containerType != CHUNKNAME('A','I','F','C')))
  )
[ERROR appendToError:@"Outermost chunk in AIFF file isn't FORM/AIF\n"];

return self;
}


-(void) dealloc 
{
if(decoder)
    [decoder release];
  if(formatData) 
    free(formatData);
}


-(long) dataLength
{
long result;
[self initializeDecompression];
result = NSSwapBigLongToHost(*((long*)(formatData+2)))*
       formatSampleSize([self outputFormat])*
       NSSwapBigShortToHost(*((short*)(formatData+0)));
	// frames * sample size (in bytes !)* num channels

if(inputFormat == SND_FORMAT_IMAADPCM_APPL)
	result = result * 34*2;			// I©d like to find a reference on this ???
						// (Hacked from IMADPCM AIFF-C files)
						// the factor two is to take into account the file is in nybbles
return result;
}

-(short) outputFormat
{
[self initializeDecompression];
return [decoder outputFormat];
}

-(short) inputFormat;
{
[self initializeDecompression];
return inputFormat;
}


-(void)popStack
{
   
if ((currentChunk >= 0) && (!chunk[currentChunk].isContainer))
   {
   unsigned long lastChunkSize = chunk[currentChunk].size;
   if (lastChunkSize & 1) 
     {  // Is there padding?
      chunk[currentChunk].remaining++;
      lastChunkSize++; // Account for padding in the container update
      }

   skipBytes(file,chunk[currentChunk].remaining); // Flush the chunk
   currentChunk--;  // Drop chunk from the stack
   // Sanity check: containing chunk must be container
   if ((currentChunk < 0) || (!chunk[currentChunk].isContainer)) 
      {
      [ERROR appendToError:@"Chunk contained in non-Container\n"];
      return;
      }
   // Reduce size of container
   if (currentChunk >= 0) 
      {
      // Sanity check: make sure container is big enough.
      // Also, avoid a really nasty underflow situation.
      if ((lastChunkSize+8) > chunk[currentChunk].remaining) 
	{
         [ERROR appendToError:@"Error: Chunk is too large to fit in container\n"];
         chunk[currentChunk].remaining = 0; // container is empty
        } 
     else
         chunk[currentChunk].remaining -= lastChunkSize + 8;
     }
  }
   
// There may be forms that are finished, drop them too
while (  (currentChunk >= 0)  &&  (chunk[currentChunk].remaining < 8))
   {
   unsigned long lastChunkSize;

   skipBytes(file,chunk[currentChunk].remaining); // Flush it
   lastChunkSize = chunk[currentChunk].size;
   currentChunk--;  // Drop container chunk
   // Sanity check, containing chunk must be container
   if (!chunk[currentChunk].isContainer) 
     {
      [ERROR appendToError:@"Chunk contained in non-container\n"];
      return;
     }
   // Reduce size of container
   if (currentChunk >= 0) 
      {
      if ((lastChunkSize+8) > chunk[currentChunk].remaining) 
	 {
         [ERROR appendToError:@"Error in aiff file: Chunk is too large to fit\n"];
         lastChunkSize = chunk[currentChunk].remaining;
         }
      chunk[currentChunk].remaining -= lastChunkSize + 8;
      }
   }
}

-(BOOL) readAiffSpecificChunk:(unsigned long) type forSize: (unsigned long) size
{
   
if (type == CHUNKNAME('F','O','R','M')) 
   {
   chunk[currentChunk].isContainer = YES;
   // Need to check size of container first.
   chunk[currentChunk].containerType = nx_rblong(file);
   chunk[currentChunk].remaining -= 4;
   if (currentChunk > 0) 
      [ERROR appendToError:@"FORM chunk seen at inner level\n"];
   return YES;
  }
if ((currentChunk >= 0) && (chunk[0].type != CHUNKNAME('F','O','R','M')))
   {
   [ERROR appendToError:@"Outermost chunk is not FORM\n"];
   currentChunk = -1;
   return YES;
   }
if (type == CHUNKNAME('F','V','E','R')) 
   {
   unsigned long version = nx_rblong(file);
   if (version != (unsigned long)2726318400) 
      {
      [ERROR appendToError:@"Unrecognized AIFC file format.\n"];
      //exit(1);  return NO ?
      }
   chunk[currentChunk].remaining -= 4;
   return YES;
}
if (type == CHUNKNAME('C','O','M','M')) 
   {
   if (currentChunk != 1)
      [ERROR appendToError:@"COMM chunk seen at wrong level\n"];

   formatData = malloc( sizeof(unsigned char)*(size+2));
   formatDataLength = fread(formatData,1,size,file);
   chunk[currentChunk].remaining = 0;
   return YES;
   }
if (type == CHUNKNAME('S','S','N','D')) 
   {
   skipBytes(file,8);
   chunk[currentChunk].remaining -= 8;
   return YES;
   }
   return NO;
}

-(BOOL) readIffGenericChunk:(unsigned long) type forSize: (unsigned long) size
{
   
if (type == CHUNKNAME('A','N','N','O'))  // Comment
   {
   [self dumpTextChunk:"Annotation:" forSize: size];
   return YES;
   }
if (type == CHUNKNAME('(','c',')',' '))  // Copyright
   {
   [self dumpTextChunk: "Copyright:" forSize: size];
   return YES;
   }
if (type == CHUNKNAME('N','A','M','E'))  // Name of work
   {
   [self dumpTextChunk: "Name:" forSize: size];
   return YES;
   }
if (type == CHUNKNAME('A','U','T','H'))  // Author
   {
   [self dumpTextChunk: "Author:" forSize: size];
   return YES;
   }
   return NO;
}

// Dump text chunk
-(void) dumpTextChunk:(const char *)name forSize: (unsigned long) size
{
   char *text = malloc( sizeof(char)*(size+2));
   long length = fread(text,1,size,file);

   chunk[currentChunk].remaining -= length;
   text[length] = 0;
   printf(name);
   printf(" ");
   printf(text);
   printf("\n");
   free(text);
}


-(void) nextChunk
{
unsigned long type;
unsigned long size;
char code[5] = "CODE";

   [self popStack];

   // Read the next chunk
   if (feof(file)) 
   {
      currentChunk = -1; // empty the stack
      return;
   }
   type = nx_rblong(file);
   size = nx_rblong(file);
   if (feof(file)) 
   {
      currentChunk = -1; // empty the stack
      return;
   }

   currentChunk++;
   chunk[currentChunk].type = type;
   chunk[currentChunk].size = size;
   chunk[currentChunk].remaining = size;
   chunk[currentChunk].isContainer = NO;
   chunk[currentChunk].containerType = 0;

   if ([self readAiffSpecificChunk:type forSize: size]) 
	return;
   if ([self readIffGenericChunk:type forSize: size]) 
	return;

   code[0] = (type>>24)&255;   code[1] = (type>>16)&255;
   code[2] = (type>>8 )&255;   code[3] = (type    )&255;
   [ERROR appendToError:@"Ignoring unrecognized `"];
   [ERROR appendToError:[NSString stringWithCString:code length:4]];
   [ERROR appendToError:@"' chunk\n"];
}

-(void) minMaxSamplingRate:(long *)min: (long *)max: (long *)preferred
{
   long sampRate;
   unsigned ieeeExponent;
   unsigned long ieeeMantissaHi;

   [self initializeDecompression];

   ieeeExponent = NSSwapBigShortToHost(*((short*)(formatData+8)));		// ????
   ieeeMantissaHi = NSSwapBigLongToHost(*((long*)(formatData+10)));	// ????
   ieeeExponent &= 0x7FFF; // Remove sign bit (rate can't be < 0)
   sampRate = ieeeMantissaHi >> (16414 - ieeeExponent);

   *min = *max = *preferred = sampRate;
}

-(void) minMaxChannels:(long*)min:(long*)max:(long *)preferred  
{
   unsigned long chan;
   [self initializeDecompression];
   chan = NSSwapBigShortToHost(*((short*)(formatData+0)));		// ????
   *min = *max = *preferred = chan;
}



- (long) getSamples:(void*)samplesBuffer forSize:(long)size
{
   if (!decoder) 
	[self initializeDecompression];
return [decoder getSamples: samplesBuffer forSize:size];
}

-(void) initializeDecompression
{
unsigned long type;

   if (decoder) 
	return;

   // Make sure we've read the COMM chunk
   while (!formatData) 
   {
      [self nextChunk];
      if (currentChunk < 0) 
	{
         [ERROR appendToError:@"No `COMM' chunk found\n"];
         return;
       }
   }

   // Select decompressor based on compression type
   type = CHUNKNAME('N','O','N','E'); // Default is none
   if (formatDataLength >= 22)
       type = NSSwapBigLongToHost(*((long*)(formatData+18)));

   
if (type == CHUNKNAME('N','O','N','E')) 
   {  // PCM format
   unsigned long bitsPerSample = NSSwapBigShortToHost(*((short*)(formatData+6)));
   
   if (bitsPerSample <= 8) // Aiff stores 8-bit data as signed
	{
   	decoder = [[FeedForwardDecoder alloc] initWithPrevious:self];
   	inputFormat = SND_FORMAT_LINEAR_8;
	}
   else if (bitsPerSample <= 16) // 16 bit data is signed
	{
    	decoder = [[FeedForwardDecoder alloc] initWithPrevious:self];
   	inputFormat = SND_FORMAT_LINEAR_16;
	}
   }
if (type == CHUNKNAME('u','l','a','w'))   // u-Law format
	{
	decoder = [[FeedForwardDecoder alloc] initWithPrevious:self];
	inputFormat = SND_FORMAT_MULAW_8;
	}

if (type == CHUNKNAME('i','m','a','4'))  // IMA ADPCM format
	{
        int chan = NSSwapBigShortToHost(*((short*)(formatData+0)));
        decoder = [[ImaAdpcmAppleDecoder alloc] initWithPrevious:self channels:chan];
        inputFormat = SND_FORMAT_IMAADPCM_APPL;
	}

   if (!decoder) 
      {
      char code[5] = "CODE";
      code[0] = (type>>24)&255;   code[1] = (type>>16)&255;
      code[2] = (type>>8 )&255;   code[3] = (type    )&255;
      [ERROR appendToError:@"AIFF-C compression type "];
      [ERROR appendToError:[NSString stringWithCString:code length:4]];
      [ERROR appendToError:@"not supported\n"];
      return;
      }
}


- (long) readBytes:(void*)bytesBuffer forSize:(long)size 
{
   while (chunk[currentChunk].type != CHUNKNAME('S','S','N','D')) 
      {
      [self nextChunk];
      if (currentChunk < 0) // stack empty?
	{          
	[ERROR appendToError:@"Sound data not found\n"];
        return 0;
        }
      }
   if (size > chunk[currentChunk].remaining)
   	size = chunk[currentChunk].remaining;
   size = fread(bytesBuffer,1, size,file);

   chunk[currentChunk].remaining -= size;
   return size;
}

@end
