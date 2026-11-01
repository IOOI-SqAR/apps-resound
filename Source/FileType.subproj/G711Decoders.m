/** g711Decoders.m
Copyright (c) 1998 Jerome Genest.  All rights reserved.
jgenest@gel.ulaval.ca

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

#import "G711Decoders.h"
#import "SoundFormats.h"
#import "g711.h"



@implementation ALawDecoder

- (long) getSamples:(void*)samplesBuffer forSize:(long)size;
{
long i;
short *buffer = samplesBuffer;
unsigned char* byteBuff = samplesBuffer;
long read = [self readBytes:byteBuff forSize:size];
   for(i=read-1; i>=0; i--)
   	//buffer[i] = aLawDecodeTable[ byteBuff[i] ];
   	buffer[i]  =alaw2linear(byteBuff[i]);

   return read*2; // read 8bits, returning 16 bits !!!
}


-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(short) inputFormat
{
return SND_FORMAT_ALAW_8;
}
@end


@implementation ULawDecoder

- (long) getSamples:(void*)samplesBuffer forSize:(long)size;
{
long i;
short *buffer = samplesBuffer;
unsigned char* byteBuff = samplesBuffer;
long read = [self readBytes:byteBuff forSize:size];
   for(i=read-1; i>=0; i--)
        //buffer[i] = aLawDecodeTable[ byteBuff[i] ];
        buffer[i]  =ulaw2linear(byteBuff[i]);

   return read*2; // read 8bits, returning 16 bits !!!
}


-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(short) inputFormat
{
return SND_FORMAT_MULAW_8;
}
@end