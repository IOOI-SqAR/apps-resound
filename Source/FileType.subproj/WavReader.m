/** wavReader.m
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

 
#import "WavReader.h"
#import "FeedForwardDecoder.h"
#import "UnsignedToSigned8BitsDecoder.h"
#import "LSB16BitsDecoder.h"
#import "G711Decoders.h"
#import "G721Decoder.h"
#import "ImaadpcmDecoders.h"

#import "ErrorHandler.h"

//#include "imaadpcm.h"
//#include "g711.h"
//#include <cstdlib>

BOOL isWaveFile(FILE *file) 
{
unsigned long form;
unsigned long type;

   rewind(file); // Seek to beginning of file
   form = nx_rblong(file);
   if (form != CHUNKNAME('R','I','F','F'))
      return NO; // Not RIFF file
   skipBytes(file,4);  // Skip chunk size
   type = nx_rblong(file);
   if (type == CHUNKNAME('W','A','V','E'))
      return YES;
   return NO; // RIFF file, but not WAVE file
}


@implementation WavReader


-initFromFile:(FILE*)theFile
{
[super initFromFile:theFile];

formatData = 0;
formatDataLength = 0;
dataLength = 0;
currentChunk = -1; // Empty the stack
[self nextChunk];

// Ensure first chunk is a FORM/AIFF container
// Ensure first chunk is RIFF/WAVE container
if (  (currentChunk != 0)
  || (chunk[0].type != CHUNKNAME('R','I','F','F'))
  || (chunk[0].isContainer != YES)
  || (chunk[0].containerType != CHUNKNAME('W','A','V','E'))
  )
        [ERROR appendToError:@"Outermost chunk in WAVE file isn't RIFF\n"];

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
int tempCurrentChunk;
iffchunkInfo tempChunkInfo[5];
short i=0;
unsigned long dataSize;
long fpos;

if(dataLength)			// this speeds up multiple calls
        return dataLength;

[self initializeDecompression];

// saving file and object state inforamtion

fpos = ftell(file); // getting current file position 
tempCurrentChunk = currentChunk;
while(i<5)
 {
 tempChunkInfo[i] = chunk[i];
 i++;
 }

// looking for data chunk and its size

while (chunk[currentChunk].type != CHUNKNAME('d','a','t','a'))
   {
   [self nextChunk];
   if (currentChunk < 0) // stack empty?
     {
     [ERROR appendToError:@"Sound data not\n"];
     return 0;
     }
   }


 dataSize = chunk[currentChunk].remaining;


// restoring old data and state info

i=0;
while(i<5)
 {
 chunk[i] = tempChunkInfo[i];
 i++;
 }

currentChunk = tempCurrentChunk;

clearerr(file);
// resseting file position as it was before
fseek(file,fpos,SEEK_SET);
clearerr(file);


dataLength = dataSize*
       formatSampleSize([self outputFormat])/formatSampleSize([self inputFormat]);
        // frames * sample size (in bytes !)* (num channels ?)
return dataLength;
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


-(FILE *)file
{
return file;
}

-(void) nextChunk
{
unsigned long type;
unsigned long size;
char code[5] = "CODE";
   
if ((currentChunk >= 0) && (!chunk[currentChunk].isContainer)) 
	{
   	unsigned long lastChunkSize = chunk[currentChunk].size;
   	if (lastChunkSize & 1) {  // Is there padding?
        chunk[currentChunk].remaining++;
        lastChunkSize++; // Account for padding in the container update
   	}

   skipBytes(file,chunk[currentChunk].remaining); // Flush the chunk
   currentChunk--;  // Drop chunk from the stack
   // Sanity check: containing chunk must be container
   if ((currentChunk < 0) || (!chunk[currentChunk].isContainer))
      [ERROR appendToError:@"Chunk contained in non-Container\n"];

   // Reduce size of container
   if (currentChunk >= 0) {
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
while (  (currentChunk >= 0)  // there is a chunk
      &&  (chunk[currentChunk].remaining < 8)
      )
	{
	unsigned long lastChunkSize;
	
   	skipBytes(file,chunk[currentChunk].remaining); // Flush it
   	lastChunkSize = chunk[currentChunk].size;
   	currentChunk--;  // Drop container chunk

   	// Sanity check, containing chunk must be container
   	if (!chunk[currentChunk].isContainer) 
      		[ERROR appendToError:@"Chunk contained in non-container\n"];

   	// Reduce size of container
  	if (currentChunk >= 0) 
		{
      		if ((lastChunkSize+8) > chunk[currentChunk].remaining) 
			{
         		[ERROR appendToError:@"Error in WAVE file: Chunk is too large to fit\n"];
         		lastChunkSize = chunk[currentChunk].remaining;
      			}
      		chunk[currentChunk].remaining -= lastChunkSize + 8;
   		}
	}

   // Read the next chunk
   if (feof(file)) 
	{
      	currentChunk = -1; // empty the stack
      	return;
   	}
   type = nx_rblong(file);
   size = nx_rllong(file);
   if (feof(file)) 
	{
      	currentChunk = -1; // empty the stack
      	return;
   	}

   // Put this chunk on the stack
   currentChunk++;
   chunk[currentChunk].type = type;
   chunk[currentChunk].size = size;
   chunk[currentChunk].remaining = size;
   chunk[currentChunk].isContainer = NO;
   chunk[currentChunk].containerType = 0;

   
if ((currentChunk >= 0) && (chunk[0].type != CHUNKNAME('R','I','F','F')))
	{
   	[ERROR appendToError:@"Outermost chunk is not RIFF\n"];
   	currentChunk = -1;
   	return;
	}
if (type == CHUNKNAME('R','I','F','F')) 
	{
   	chunk[currentChunk].isContainer = YES;
   	// Need to check size of container first.
	chunk[currentChunk].containerType = nx_rblong(file);
  	 chunk[currentChunk].remaining -= 4;
   	if (currentChunk > 0) 
		{
      		[ERROR appendToError:@"RIFF chunk seen at inner level\n"];
   		}
   	return;
	}
if (type == CHUNKNAME('f','m','t',' ')) 
	{
   	if (currentChunk != 1) 
		{
      		[ERROR appendToError:@"FMT chunk seen at wrong level\n"];
   		}
   	formatData = malloc(sizeof(unsigned char)*(size+2));
	formatDataLength = fread(formatData,1,size,file);
   	chunk[currentChunk].remaining = 0;
   	return;
	}
if (type == CHUNKNAME('d','a','t','a')) 
	{
   	return;
	}

if ((type & 0xFF000000) == CHUNKNAME('I',0,0,0)) 
	{ // First letter 'I'??
	long length;
   	char *text = malloc(sizeof(char)*(size+2));
        length =fread(text,1,size,file);

   	chunk[currentChunk].remaining -= length;
   	text[length] = 0;
   	if (type == CHUNKNAME('I','C','M','T')) // Comment
      		printf("Comment: ");
   	else if (type == CHUNKNAME('I','C','O','P')) // Copyright notice
      		printf("Copyright: ");
   	else if (type == CHUNKNAME('I','N','A','M')) // Name of work
      		printf("Title: ");
   	else if (type == CHUNKNAME('I','A','R','T')) // Name of artist
      		printf("Artist: ");
   	else
      		printf("Text: "); // Other Informational chunk
   	printf(text);
	printf("\n");
   	return;
	}

   code[0] = (type>>24)&255;   code[1] = (type>>16)&255;
   code[2] = (type>>8 )&255;   code[3] = (type    )&255;

   [ERROR appendToError:@"Ignoring unrecognized `"];
   [ERROR appendToError:[NSString stringWithCString:code length:4]];
   [ERROR appendToError:@"' chunk\n"];
}


-(void) minMaxSamplingRate:(long *)min: (long *)max: (long *)preferred
{
unsigned long sampRate;

   [self initializeDecompression];
   sampRate = NSSwapLittleLongToHost( *((long*)(formatData+4)) );
   *max = *min = *preferred = sampRate;
}

-(void) minMaxChannels:(long*)min:(long*)max:(long *)preferred  
{
unsigned long chan; 

[self initializeDecompression];
chan = NSSwapLittleShortToHost( *((short*)(formatData+2)) );
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

   // Make sure we've read the fmt chunk
   while (!formatData) 
	{
   	[self nextChunk];
      	if (currentChunk < 0) 
		{
        	 [ERROR appendToError:@"No `fmt' chunk found\n"];
        	 return;
      		}
   	}

   // Select decompressor based on compression type
   type = NSSwapLittleShortToHost( *((short*)(formatData+0)) );

   
if (type == 1) 
	{  // PCM format
	unsigned long bitsPerSample = NSSwapLittleShortToHost( *((short*)(formatData+14)) );
   	if (bitsPerSample <= 8) // Wave stores 8-bit data as unsigned
      		{
		decoder = [[UnsignedToSigned8BitsDecoder alloc] initWithPrevious:self];
        	inputFormat = SND_FORMAT_LINEAR_8;
		}
   	else if (bitsPerSample <= 16) // 16 bit data is signed
      		{
       	 	decoder = [[LSB16BitsDecoder alloc] initWithPrevious:self];
        	inputFormat = SND_FORMAT_LINEAR_16;
        	}
	}
if (type == 17) 
	{  // IMA ADPCM format
	int packetLength;
	int chan;

   	unsigned long bitsPerSample = NSSwapLittleShortToHost( *((short*)(formatData+14)) );
   	if (bitsPerSample != 4) 
		{
		char tempString[80];
      		sprintf(tempString,"IMA ADPCM requires 4 bits per sample, not the case %f\n",(float) bitsPerSample);
      		[ERROR appendToError:[NSString stringWithCString:tempString]];
      		return;
   		}
   	if (formatDataLength < 20) 
		{
      		[ERROR appendToError:@"IMA ADPCM requires additional decompression data.\n"];
      		return;
   		}
        packetLength = NSSwapLittleShortToHost( *((short *)(formatData+18)) );
        chan = NSSwapLittleShortToHost( *((short *)(formatData+2)) );
        decoder = [[ImaAdpcmMsDecoder alloc] initWithPrevious:self packetLength: packetLength channels :chan];
        inputFormat = SND_FORMAT_IMAADPCM_MS;      
	}

if (type == 6) 
	{
	decoder = [[ALawDecoder alloc] initWithPrevious:self];
	inputFormat = SND_FORMAT_ALAW_8;
	}

if (type == 7)
	{
	decoder = [[FeedForwardDecoder alloc] initWithPrevious:self];
	inputFormat = SND_FORMAT_MULAW_8;
	}

if (type == 64)	// ITU G.721 ADPCM
        {
	decoder = [[G721Decoder alloc] initWithPrevious:self];
	inputFormat = SND_FORMAT_ADPCM_G721;
        }

if (type == 64)	// ITU G.721 ADPCM
        {
        decoder = [[G721Decoder alloc] initWithPrevious:self];
        inputFormat = SND_FORMAT_ADPCM_G721;
        }

if (type == 2) 
	{
	[ERROR appendToError:@"MS ADPCM compression not supported\n"];
	}

if (!decoder) 
	{
	char tempString[80];
     	sprintf(tempString,"I don't support WAVE compression type %f\n",(float)type);
        [ERROR appendToError:[NSString stringWithCString:tempString]];
      	return;
   	}
}

- (long) readBytes:(void*)bytesBuffer forSize:(long)size
{
   while (chunk[currentChunk].type != CHUNKNAME('d','a','t','a'))
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