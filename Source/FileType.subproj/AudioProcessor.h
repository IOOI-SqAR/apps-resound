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

#import <AppKit/AppKit.h>


unsigned short nx_rlshort(FILE *stream);
unsigned short nx_rbshort(FILE *stream);
unsigned long nx_rllong(FILE *stream);
unsigned long nx_rblong(FILE *stream);
void skipBytes(FILE *in, int size);
long readIntLsb(FILE *in, int size) ;

@interface AudioProcessor:NSObject
{
   id previous; // object to get data from
   id next; // object pulling data from us

   long samplingRate;
   BOOL samplingRateFrozen;
   BOOL channels;
   BOOL channelsFrozen;
   
   short sampleSize;

   short inputFormat;
   short outputFormat;
}



- init;
- initWithPrevious:previous;

-(short) outputFormat;
-(short) inputFormat;

- (id) previous;
- (id) next;
-(void) setNext:theNext;

- (long) getSamples:(void*)samplesBuffer forSize:(long)size;
- (long) readBytes:(void*)bytesBuffer forSize:(long)size;


- (double) samplingRate;
- (void) setSamplingRate:(long)s;
- (void) negotiateSamplingRate;
- (void) minMaxSamplingRate:(long*) min :(long*) max: (long*) prefer;
- (void) setSamplingRateRecursive:(long) s;

- (int) channels;
- (void) setChannels:(int) ch;
- (void) negotiateChannels;
- (void) minMaxChannels:(long*) min :(long*) max: (long*) prefer;
- (void) setChannelsRecursive:(int) s;
@end
