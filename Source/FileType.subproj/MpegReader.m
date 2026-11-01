/** mpegReader.m
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

#import "MpegReader.h"
#import "MpegDecoder.h"

BOOL isMpegFile(FILE *file) 
{
long magic;
long curPos;
BOOL returnValue;
curPos = ftell(file);

rewind(file); // Seek to beginning of file
magic = nx_rbshort(file);   
if ((magic & 0xFFF0) == 0xFFF0)
	returnValue =  YES;
else
	returnValue =  NO;

fseek(file,curPos,SEEK_SET);

return returnValue;
}

@implementation MpegReader

-initFromFile:(FILE*)theFile
{
[super initFromFile:theFile];

decoder = [[MpegDecoder alloc] initWithPrevious:self];
dataLength=0;
return self;
}


-(void) dealloc
{
if(decoder)
    [decoder release];
}

-(long) dataLength
{
if(dataLength)
	return dataLength;
dataLength = [decoder dataLength:file];
return dataLength; 
}

-(short) outputFormat
{
return [decoder outputFormat];
}

-(short) inputFormat;
{
return inputFormat;
}


- (long) getSamples:(void*)samplesBuffer forSize:(long)size 
{
return [decoder getSamples:samplesBuffer forSize:size];
}

- (long) readBytes:(void*)bytesBuffer forSize:(long)size 
{
return fread(bytesBuffer,1,size,file);
}

-(void) minMaxChannels:(long*)min:(long*)max:(long *)preferred 
{
   [decoder minMaxChannels:min : max : preferred];
}

-(void) minMaxSamplingRate:(long *)min: (long *)max: (long *)preferred
 {
   [decoder minMaxSamplingRate: min : max : preferred];
}

@end
