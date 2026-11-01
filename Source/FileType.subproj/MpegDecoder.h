/** mpegDecoder.m
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

#import <AppKit/AppKit.h>
#import "AudioProcessor.h"

typedef struct
{
   long levels;  // Number of levels
   char bits;    // bits to read
   BOOL grouping;// Yes->decompose into three samples
} layer2QuantClass;



typedef struct
{
   char numberBits;
   layer2QuantClass **quantClasses;
}layer2BitAllocationTableEntry;


@interface MpegDecoder:  AudioProcessor 
{
char ID; // 1 for MPEG-1, 0 for MPEG-2 extensions
char layer;
char protection; // 1 if CRC check omitted
long bitRate; // total bits/second
//long samplingRate; // samples/second
BOOL padding; // this packet has an extra slot
char private; // private bit
char mode;   // single-channel, dual-channel, stereo, etc.
char modeExtension; // Type of stereo encoding
char bound; // subband where stereo encoding changes
BOOL copyright; // true if copyrighted
BOOL original; // true if original
char emphasis; // How to post-process audio
//int channels; // Number channels
int headerSpacing; // in bytes

unsigned char bufferStorage[2048];

unsigned char *buffer; // Beginning of live data in buffer
int  bitsRemaining; // bits left in top byte
unsigned char *bufferEnd; // End of live data in buffer
unsigned char *header; // Location of header in buffer

long *V[2][16];  // Synthesis window for left/right channel

short sampleStorage[2][11521];
short *pcmSamples[2]; // Samples for left/right channels
int samplesRemaining; // Samples remaining from last frame
}

-(void) fillBuffer; // Keep byte buffer full
-(void) resetBits; // Reset bit extraction
-(long) getBits:(int) numBits; // Extract bits

-(BOOL) parseHeader; // Parse header for next frame


-(void) layer12Synthesis:(long**) V :(long*) subbandSamples: (int) numSubbandSamples :(short*) pcmSamples;
//-(void) Layer12Synthesis:(long**)V :(long *)in: (int) inSamples:(short *) out;
-(void) layer1Decode; // Decompress layer 1 data
-(void) layer2Decode; // Decompress layer 2 data
-(void) layer3Decode;

-(void) nextFrame; // Read and decompress next frame

- initWithPrevious:previous;

-(void)dealloc;

- (long) getSamples:(void*)samplesBuffer forSize:(long)size;

- (void) minMaxSamplingRate:(long*) min :(long*) max: (long*) prefer;
- (void) minMaxChannels:(long*) min :(long*) max: (long*) prefer;

-(long) dataLength:(FILE*)file;

@end

