/** vocReader.m
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

#import "UnsignedToSigned8BitsDecoder.h" 
#import "FeedForwardDecoder.h"
#import "LSB16BitsDecoder.h"
#import "G711Decoders.h"
#import "VocReader.h"
#import "SoundFormats.h"

#import "ErrorHandler.h"

/** My VOC sample file is not read correctly by this code **/
/** I thinf the problem is with the file: incorrect number **/
/** of data stated in the header block **/
/** I'll need to check this with another file **/

/** The final result is however correct since it was not a complicated file **/

/** Jerome Genest april 30, 1998 **/ 


BOOL isVocFile(FILE *file) 
{
   char id[21];
   rewind(file); // Seek to beginning of file
   
   fread(id,1,20,file);
   return (!strncmp(id,"Creative Voice File\x1a",20));
}

@implementation  VocReader
-(void) readHeader
 {
   char id[21];
   int headerSize, fileVersionCode, fileVersionCheck;

   fread(id,1,20,file);
   if (strncmp(id,"Creative Voice File\x1a",20)) 
	{
      	[ERROR appendToError:@"This is not a VOC file.\n"];
      	return;
   	}
   headerSize = nx_rlshort(file);
   if (headerSize < 26) 
	{
      	[ERROR appendToError:@"This VOC file is corrupted.\n"];
      	return;
   	}

   fileVersionCode = nx_rlshort(file);
   fileVersionCheck = nx_rlshort(file);

   if (fileVersionCode + fileVersionCheck != 0x1233)
   	[ERROR appendToError:@"This VOC file is corrupted.\n"];


   // Is header larger than 26 bytes?
   if (headerSize > 26)
      skipBytes(file,26-headerSize); // Skip rest
}


-(void) getBlock
 {
   long blockLength = 0;
   
   blockType = readIntLsb(file,1);
   if(feof(file)) blockType = 0;
   if (blockType != 0)
      blockLength = readIntLsb(file,3);

   switch(blockType) 
	{
   	int sampleRateCode;
      
	case 0: // End of data
   		break;
	case 1: // Sound Data Block
   		[self readBlock1:blockLength];
   		break;
	case 2:  // Sound Data Continued
   		bytesRemaining = blockLength;
   		break;
	case 3: // Silence
		{
   		if (blockLength != 3)
			{
			char tempString[80];
                	sprintf(tempString,"VOC Silence Block has length %f (should be 3)\n", (float)blockLength);
      			[ERROR appendToError:[NSString stringWithCString:tempString]];
   			}
   		bytesRemaining = readIntLsb(file,2) + 1;
   		sampleRateCode = readIntLsb(file,1);
   		if (fileSampleRate == -1)
   			fileSampleRate = 1000000/(256-sampleRateCode);
   		bytesRemaining = blockLength - 3;
   		break;
		}
	case 4: // Marker block
   		if (blockLength != 2) 
			{
			char tempString[80];
                	sprintf(tempString,"VOC Marker Block has length %f (should be 2)\n",(float) blockLength);
                        [ERROR appendToError:[NSString stringWithCString:tempString]];
   			}
        	//printf("VOC Marker: ");
   		//printf("%f",(float)ReadIntLsb(file,blockLength));
   		//pritnf("\n");
   		bytesRemaining = blockLength - 2;
   		break;
	case 5: // ASCII text block
		{
   		char *text = malloc(sizeof(char)*(blockLength+1));
   		fread(text,1,blockLength,file);
   		text[blockLength] = 0;
   		//printf("Comment: ");
		//printf(text);
		//printf("\n");
   		free(text);
   		bytesRemaining = 0;
   		break;
		}
	case 6: // Repeat loop
		{
                int repeatCount;

   		if (blockLength != 2) 
			{
			char tempString[80];
                	sprintf(tempString,"VOC Repeat Loop Block has length %f (should be 2)\n",(float)blockLength);
                	[ERROR appendToError:[NSString stringWithCString:tempString]];
   			}
                //printf("Start of VOC Repeat Block.\n");
   		repeatCount = readIntLsb(file,2);
   		repeatDepth++;
   		if (repeatDepth > MAXREPEAT) 
			{
      			[ERROR appendToError:@"Too many nested repeats.\n"];
      			return;
   			}
   		repeatCounts[repeatDepth] = repeatCount;
   		repeatPosition[repeatDepth] = ftell(file);
   		bytesRemaining = blockLength - 2;
  		break;
		}
	case 7: // Repeat end
		{
   		bytesRemaining = blockLength;
   		if (blockLength != 0) 
			{
			char tempString[80];
                	sprintf(tempString,"VOC `End Repeat' block has length %f (should be 0)\n", (float)blockLength);
      			[ERROR appendToError:[NSString stringWithCString:tempString]];
  			 }
   		if (repeatDepth < 0) 
			{
      			[ERROR appendToError:@"Improper VOC `End Repeat' block.\n"];
      			break;
   			}
   		// On Mac, the repeatCounts[repeatDepth] always prints as 1 or 0 ??
   		// Is this a bug in the C++ library?
   		//printf("End of VOC Repeat Block(");
   		//printf("%f",(float)repeatCounts[repeatDepth]); 
		//printf(")\n");
   		if (repeatCounts[repeatDepth] <= 0) 
			{ // End of repeat?
      			repeatDepth--;
   			} 
		else 
			{ // Position for next iteration
      			fseek(file, repeatPosition[repeatDepth],SEEK_SET);
      			repeatCounts[repeatDepth]--;
   			}
  		 break;
		}
	case 8: // Extension
   		[self readBlock8:blockLength];
   		break;
	case 9: // Extension
   		[self readBlock9:blockLength];
   		break;
	default: // Skip any other type of block
		{
		char tempString[80];
   		sprintf(tempString,"Ignoring unrecognized VOC block type %d\n", blockType);
                [ERROR appendToError:[NSString stringWithCString:tempString]];
   		skipBytes(file,blockLength);
		}
   		break;

   	}
}


-(void) readBlock1:(long) blockLength 
{
   // Read and interpret first two bytes...
   int sampleRateCode = readIntLsb(file,1);
   int compressionCode = readIntLsb(file,1);
   if (fileSampleRate == -1)
      fileSampleRate = 1000000L/(256-sampleRateCode);
   if (fileCompression == -1)
      fileCompression = compressionCode;
   if (fileChannels == -1)
      fileChannels = 1;
   if (fileWidth == -1)
      fileWidth = 8;
   if (decoder == 0) 
   { // No decoder object yet?
      switch(fileCompression) 
      {
      case 0: // Unsigned 8-bit PCM
      	 decoder = [[UnsignedToSigned8BitsDecoder alloc] initWithPrevious:self];
         inputFormat = SND_FORMAT_LINEAR_8;
         break;
      case 4: // Signed 16-bit PCM
      	  decoder = [[LSB16BitsDecoder alloc] initWithPrevious:self];
  	 inputFormat = SND_FORMAT_LINEAR_16;
         break;
      case 6: // CCITT A-Law
          decoder = [[ULawDecoder alloc] initWithPrevious:self];
           inputFormat = SND_FORMAT_MULAW_8;
           break;
      case 7: // CCITT mu-Law
          decoder = [[ALawDecoder alloc] initWithPrevious:self];
          inputFormat = SND_FORMAT_ALAW_8;
          break;
      case 1: // Creative Labs 8-bit to 4-bit ADPCM
      case 2: // Creative Labs 8-bit to 2.6-bit ADPCM
      case 3: // Creative Labs 8-bit to 2-bit ADPCM
      case 512: // Creative Labs 16-bit to 4-bit ADPCM
      default:
	{
	char tempString[80];
      	sprintf(tempString,"I don't support VOC compression type %d\n",fileCompression);
        [ERROR appendToError:[NSString stringWithCString:tempString]];
	}
        return;
      }
   }
   bytesRemaining = blockLength - 2;
}

-(void) readBlock8:(long) blockLength 
{
int sampleRateCode;
int compressionCode;
int chan;

   if (blockLength != 4) 
	{
	char tempString[80];
   	sprintf(tempString,"VOC Extension Block 8 has length %f (should be 4)\n",(float)blockLength);
        [ERROR appendToError:[NSString stringWithCString:tempString]];
   	}
   sampleRateCode = readIntLsb(file,2);
   if (fileSampleRate == -1)
      fileSampleRate = 256000000L/(65536L-sampleRateCode);
   compressionCode = readIntLsb(file,1);
   if (fileCompression == -1)
      fileCompression = compressionCode;
   chan = readIntLsb(file,1);
   if (fileChannels == -1) 
	{
        fileChannels = chan + 1;
        fileSampleRate /= fileChannels;
   	}
   if (fileWidth == -1)
      fileWidth = 8;
   bytesRemaining = blockLength - 4;
}

-(void) readBlock9:(long) blockLength 
{
long sampleRate;
int bitsPerSample;
int chan;
int compressionCode;

   if (blockLength != 12) 
	{
   	char tempString[80];
   	sprintf(tempString,"VOC Extension Block 9 has length %f (should be 12)\n",(float)blockLength);
	[ERROR appendToError:[NSString stringWithCString:tempString]];
   	}
   sampleRate = readIntLsb(file,4);
   if (fileSampleRate == -1)
      fileSampleRate = sampleRate;
   bitsPerSample = readIntLsb(file,1);
   if (fileWidth == -1)
      fileWidth = bitsPerSample;
   chan = readIntLsb(file,1);
   if (fileChannels == -1)
      fileChannels = channels;
   compressionCode = readIntLsb(file,2);
   if (fileCompression == -1)
      fileCompression = compressionCode;
   skipBytes(file,blockLength - 8);
}


-initFromFile:(FILE*)theFile
{
[super initFromFile:theFile];

repeatDepth = -1;
   fileChannels = -1;
   fileSampleRate = -1;
   fileCompression = -1;
   fileWidth = -1;
   dataLength = 0;
[self readHeader];
do {   // Find sound data block or terminator block
      [self getBlock];
   } while ((blockType != 1) && (blockType != 0));
return self;
}

-(void) dealloc
{
if(decoder)
    [decoder release];
}

/* Must return the whole file data length */
/* i.e. walk through all the data blocks */
/* without altering the current state of the */
/* file and object variables */

-(long) dataLength
{

long fpos;
long samplesInfile = 0;
BOOL done = NO;

int savedBlockType = blockType;			// saving object state
unsigned long savedBytesRemaining = bytesRemaining;
int savedRepeatCounts[MAXREPEAT];
long savedRepeatPosition[MAXREPEAT];
int i =0;

if(dataLength)						// this speeds up multiple calls
	return dataLength;

while(i<MAXREPEAT)
	{
	savedRepeatCounts[i] = repeatCounts[i];
	savedRepeatPosition[i] = repeatPosition[i];
	i++;
	}


fpos = ftell(file);					// getting current file position 

 while (!feof(file) || done)
    {
    switch(blockType)
      {
      case 0: // End of file
              done = YES;
      case 1: // Encoded sound data
      case 2:
      case 3: // Silence block
              {
              samplesInfile += bytesRemaining;
              skipBytes(file,bytesRemaining);
              [self getBlock];
              break;
              }
      default:
       [self getBlock];
       break;
    }
 }

clearerr(file);
// resseting file position as it was before
fseek(file,fpos,SEEK_SET);
clearerr(file);

//restoring object<s state

bytesRemaining = savedBytesRemaining;
blockType = savedBlockType;

i=0;
while(i<MAXREPEAT)
        {
	repeatCounts[i] = savedRepeatCounts[i];
	repeatPosition[i]= savedRepeatPosition[i];
        i++;
        }

dataLength = samplesInfile*
       	formatSampleSize([self outputFormat])/formatSampleSize([self inputFormat]);

return dataLength;
}

-(short) outputFormat
{
return [decoder outputFormat];
}

-(void) minMaxSamplingRate:(long *)min: (long *)max: (long *)preferred
{
*min = *max = *preferred = fileSampleRate;
}

-(void) minMaxChannels:(long*)min:(long*)max:(long *)preferred
{
*min = *max = *preferred = fileChannels;
}

- (long) getSamples:(void*)samplesBuffer forSize:(long)size 
{

   char *tempPtr = (char*)samplesBuffer;
   long samplesReturned = 0;
   while (size > 0) 
      {
      switch(blockType) 
	{
      	case 0: // End of file
        	return samplesReturned;
      	case 1: // Encoded sound data
      	case 2: 
		{
                long samplesRead = [decoder getSamples:tempPtr forSize: size];
                tempPtr += samplesRead*fileWidth/8;
                size -= samplesRead;
            	samplesReturned += samplesRead;
            	if (bytesRemaining == 0) 
			[self getBlock];
            	break;
         	}
      	case 3: // Silence block
         	while ((size > 0) && (bytesRemaining > 0)) 
			{
			long i=0;
                	while(i<fileWidth/8)
				{
                        	*tempPtr++ = 0;
				i++;
				}
            		samplesReturned++;
            		size--;
            		bytesRemaining--;
         		}
         	if (bytesRemaining == 0) 
			[self getBlock];
        	 break;
      default:
         [self getBlock];
         break;
      }
   }
   return samplesReturned;
}

- (long) readBytes:(void*)bytesBuffer forSize:(long)size 
{
long bytesRead;

		if (size > bytesRemaining) 
			size = bytesRemaining;
                bytesRead = fread(bytesBuffer,1, size,file);

        if (bytesRead < size) 
		{
      		[ERROR appendToError:@"Error:  VOC file ended prematurely."];
      		return 0;
   		}
   	bytesRemaining -= bytesRead; // Amount left in block
   	return bytesRead;
}

@end
