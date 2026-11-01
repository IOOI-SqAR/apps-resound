/* soundCategories.m created by jgenest on Mon 27-Apr-1998 

Copyright (c) 1998 Jerome Genest.  All rights reserved.
jgenest@gel.ulaval.ca

This source code was insprired from and thus contains parts from:

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

#import "SoundCategories.h"
#import "AuReader.h"

#import "ErrorHandler.h"

@implementation Sound (ForeignSoundReader)


-readForeignSoundFile:fileReader
{
void *data;
long dataRead;

[ERROR clearError];

[self setDataSize:[fileReader dataLength]
        dataFormat:[fileReader outputFormat]
         samplingRate:[fileReader samplingRate]
         channelCount:[fileReader channels]
         infoSize:4];

        data = [self data];

        dataRead = [fileReader getSamples:data forSize:[fileReader dataLength]];

        if(dataRead != [fileReader dataLength])
        	[ERROR appendToError:@"Sound is smaller than expected !\n"];

[ERROR showWindowIfNeeded];

return SND_ERR_NONE;
}



@end