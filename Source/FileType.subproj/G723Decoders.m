/** g723Decoders.m
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

#import "G723Decoders.h"
#import "SoundFormats.h"
#import "g72x.h"
#import "g723_24.h"
#import "g723_40.h"


@implementation G723_24Decoder

// this is for ADPM G723.3

- (long) getSamples:(void*)samplesBuffer forSize:(long)size;
{
//long i;
short *buffer = samplesBuffer;
unsigned char* bytesBuff;
long read,samplesRead;
g72x_state state;
unsigned char code;

curBytesBuffPos = bytesBuff = malloc(sizeof(char)*size/4);	
bytesBuffEnd = bytesBuff + size/4;

read = [self readBytes:bytesBuff forSize:size];

// read is num of bytes read. 4 bits per sample in g721
samplesRead = read*4;

dec_bits=4;			// shouldn©t be 3 ???
g72x_init_state(&state);

while(samplesRead >0 && [self unpack_input:&code] >= 0)
        {
        samplesRead--;
        *buffer++ = g723_24_decoder(code, AUDIO_ENCODING_LINEAR,&state);

        //int g723_24_decoder(int i,int  out_coding,g72x_state state_ptr);
        }

free(bytesBuff);
bytesBuff = bytesBuffEnd  = 0;
curBytesBuffPos = bytesBuffEnd+1;  // to avoid buffer overflow in unpack_intput !

return read*4; // read 4bits, returning 16 bits !!!
}


-(int) unpack_input:(unsigned char *)code

{
unsigned char in_byte;

if (in_bits < dec_bits)
        {
        if (curBytesBuffPos > bytesBuffEnd)
                {
                *code = 0;
                return (-1);
                }
        else
                {
                //readNext byte from bytesBuf into inByte
                in_byte = *curBytesBuffPos++;
                }

        in_buffer |= (in_byte << in_bits);
        in_bits += 8;
        }
        *code = in_buffer & ((1 << dec_bits) - 1);
        in_buffer >>= dec_bits;
        in_bits -= dec_bits;
        return (in_bits > 0);
}

-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(short) inputFormat
{
return SND_FORMAT_ADPCM_G723_3;
}
@end








@implementation G723_40Decoder

// this is for ADPM G723.3

- (long) getSamples:(void*)samplesBuffer forSize:(long)size;
{
//long i;
short *buffer = samplesBuffer;
unsigned char* bytesBuff;
long read,samplesRead;
g72x_state state;
unsigned char code;

curBytesBuffPos = bytesBuff = malloc(sizeof(char)*size/4);	
bytesBuffEnd = bytesBuff + size/4;

read = [self readBytes:bytesBuff forSize:size];

// read is num of bytes read. 4 bits per sample in g721
samplesRead = read*4;

dec_bits=4;			// shouldn©t be 5 ???
g72x_init_state(&state);

while(samplesRead >0 && [self unpack_input:&code] >= 0)
        {
        samplesRead--;
        *buffer++ = g723_40_decoder(code, AUDIO_ENCODING_LINEAR,&state);

        }

free(bytesBuff);
bytesBuff = bytesBuffEnd  = 0;
curBytesBuffPos = bytesBuffEnd+1;  // to avoid buffer overflow in unpack_intput !

return read*4; // read 4bits, returning 16 bits !!!
}


-(int) unpack_input:(unsigned char *)code

{
unsigned char in_byte;

if (in_bits < dec_bits)
        {
        if (curBytesBuffPos > bytesBuffEnd)
                {
                *code = 0;
                return (-1);
                }
        else
                {
                //readNext byte from bytesBuf into inByte
                in_byte = *curBytesBuffPos++;
                }

        in_buffer |= (in_byte << in_bits);
        in_bits += 8;
        }
        *code = in_buffer & ((1 << dec_bits) - 1);
        in_buffer >>= dec_bits;
        in_bits -= dec_bits;
        return (in_bits > 0);
}

-(short) outputFormat
{
return SND_FORMAT_LINEAR_16;
}

-(short) inputFormat
{
return SND_FORMAT_ADPCM_G723_5;
}
@end


