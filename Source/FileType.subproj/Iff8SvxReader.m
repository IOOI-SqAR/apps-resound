/** iffReader.m
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

#import "Iff8SvxReader.h"
#import "FeedForwardDecoder.h"
#import "DpcmDecoders.h"

#import "ErrorHandler.h"


BOOL isIff8SvxFile(FILE *file) 
{
unsigned long form;
unsigned long type;

   rewind(file); // Seek to beginning of file
   form = nx_rblong(file);
   if (form != CHUNKNAME('F','O','R','M'))
      return NO; // Not IFF file
   skipBytes(file,4);  // Skip chunk size
   type = nx_rblong(file);
   if (type == CHUNKNAME('8','S','V','X'))
      return YES;
   return NO; // IFF file, but not 8SVX file
}

@implementation Iff8SvxReader


-initFromFile:(FILE*)theFile
{
[super initFromFile:theFile];
dataLength = 0;
formatData = 0;
formatDataLength = 0;

currentChunk = -1; // Empty the stack
[self nextChunk];

// Ensure first chunk is a FORM/8SVX container
if (  (currentChunk != 0)
  || (chunk[0].type != CHUNKNAME('F','O','R','M'))
  || (chunk[0].isContainer != TRUE)
  || (chunk[0].containerType != CHUNKNAME('8','S','V','X'))
  )
	[ERROR appendToError:@"Outermost chunk in IFF file isn't FORM/8SVX"];

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
{int tempCurrentChunk;
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

while (chunk[currentChunk].type != CHUNKNAME('B','O','D','Y'))
   {
   [self nextChunk];
   if (currentChunk < 0) // stack empty?
     {
     [ERROR appendToError:@"Sound data not found\n"];
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
         [ERROR appendToError:@"Error in WAVE file: Chunk is too large to fit\n"];
         lastChunkSize = chunk[currentChunk].remaining;
         }
      chunk[currentChunk].remaining -= lastChunkSize + 8;
      }
   }
}

-(BOOL) readIff8svxChunk:(unsigned long) type forSize: (unsigned long) size 
{
   
if ((currentChunk >= 0) && (chunk[0].type != CHUNKNAME('F','O','R','M')))
	{
   	[ERROR appendToError:@"Outermost chunk is not FORM\n"];
   	currentChunk = -1;
   	return NO;
	}
if (type == CHUNKNAME('F','O','R','M')) 
	{
   	chunk[currentChunk].isContainer = YES;
   	// Need to check size of container first.
	chunk[currentChunk].containerType = nx_rblong(file);
   	chunk[currentChunk].remaining -= 4;
   	if (currentChunk > 0) 
		{
      		[ERROR appendToError:@"FORM chunk seen at inner level\n"];
   		}
   	return YES;
	}
if (type == CHUNKNAME('V','H','D','R')) 
	{
   	if (currentChunk != 1) 
		{
      		[ERROR appendToError:@"VHDR chunk seen at wrong level\n"];
  		}
   	formatData = malloc(sizeof(unsigned char)*(size+2));
	formatDataLength =fread(formatData,1,size,file);
   	chunk[currentChunk].remaining = 0;
   	return YES;
	}
if (type == CHUNKNAME('B','O','D','Y')) 
	{
   	if (formatData) 
		{
      		unsigned long vhdrSamples = NSSwapBigShortToHost( *((short*)(formatData+0)) );
      		unsigned long bodyLength = chunk[currentChunk].size;

      		// Do they make any sense?
      		if ((bodyLength == 0) && (vhdrSamples == 0)) 
			{
         		[ERROR appendToError:@"IFF/8SVX file says it has no data\n"];
         		//printf("I'll try to play something anyway, here goes...\n");
         		chunk[currentChunk].size = 1000000L;
      			} 
		else if (bodyLength == 0) 
			{
         		[ERROR appendToError:@"IFF/8SVX file has samples, but the body has no data\n"];
         		[ERROR appendToError:@"Maybe the body is damaged\n"];
         		chunk[currentChunk].size = vhdrSamples;
      			} 
		else if (vhdrSamples == 0) 
			{
         		[ERROR appendToError:@"IFF/8SVX file has data in the body, but no samples\n"];
                	[ERROR appendToError:@"Maybe the body is damaged\n"];
      			}
   		}
   	return YES;
	}
return NO;
}

-(BOOL) readIffGenericChunk:(unsigned long) type forSize: (unsigned long) size
{
if (type == CHUNKNAME('A','N','N','O')) 
	{ // Comment
	[self dumpTextChunk:"Annotation:" forSize:size];
   	return YES;
	}
if (type == CHUNKNAME('(','c',')',' ')) 
	{ // Copyright
	[self dumpTextChunk:"Copyright:" forSize: size];
   	return YES;
	}
if (type == CHUNKNAME('N','A','M','E')) 
	{ // Name of work
	[self dumpTextChunk: "Name:" forSize:size];
   	return YES;
	}
if (type == CHUNKNAME('A','U','T','H')) 
	{ // Author
	[ self dumpTextChunk:"Author:" forSize:size];
   	return YES;
	}
return FALSE;
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

   if ([self readIff8svxChunk:type forSize: size])
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

   if (!decoder)
   	[self initializeDecompression];

   sampRate = NSSwapBigShortToHost(*((short*)(formatData+12)));   
   *min = *max = *preferred = sampRate;
}

-(void) minMaxChannels:(long*)min:(long*)max:(long *)preferred
{
   *min = *max = *preferred = 1;
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

   while (!formatData) 
	{    // Read the VHDR chunk
      	[self nextChunk];
      	if (currentChunk < 0) 
		{
         	[ERROR appendToError:@"No `VHDR' chunk found\n"];
         	return;
      		}
   	}

   // Select decompressor based on compression type
   type = *((char*)(formatData+15));
   
if (type == 0) 
	{  // PCM format
   	decoder = [[FeedForwardDecoder alloc] initWithPrevious:self];
	inputFormat = SND_FORMAT_LINEAR_8;
	}
if (type == 1) 
	{  // Fibonacci DPCM
	decoder = [[DpcmFibonacciDecoder alloc] initWithPrevious:self];
	inputFormat = SND_FORMAT_DPCM_FIBO;
	}
if (type == 2) 
	{  // Exponential
	decoder = [[DpcmExponentialDecoder alloc] initWithPrevious:self];
	inputFormat = SND_FORMAT_DPCM_EXP;
	}
if (!decoder) 
	{
	char tempString[80];
      	sprintf(tempString,"IFF/8SVX compression type %f not supported\n",(float)type);
	[ERROR appendToError:[NSString stringWithCString:tempString]];
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


@end
