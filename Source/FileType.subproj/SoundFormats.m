/* soundFormats.m created by jgenest 

Copyright (c) 1998 Jerome Genest.  All rights reserved.
jgenest@gel.ulaval.ca

sound formats are from Apple/Next soundkit header

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

// Returns sampleSize in Bytes, given a sound format

#import "SoundFormats.h"

float formatSampleSize(short format)
{
switch(format)
	{
	case SND_FORMAT_MULAW_8:
        case SND_FORMAT_LINEAR_8:
        case SND_FORMAT_DSP_DATA_8:		// should we ?
        case SND_FORMAT_ALAW_8:
        case SND_FORMAT_DELTA_MULAW_8:
		return 1;
	case SND_FORMAT_LINEAR_16:
        case SND_FORMAT_DSP_DATA_16:		// should we ?
	case SND_FORMAT_EMPHASIZED:           
        case SND_FORMAT_COMPRESSED:           
        case SND_FORMAT_COMPRESSED_EMPHASIZED:

		return 2;
	case SND_FORMAT_LINEAR_24:
        case SND_FORMAT_DSP_DATA_24:		// should we ?
		return 3;
	case SND_FORMAT_LINEAR_32:
	case SND_FORMAT_FLOAT:
        case SND_FORMAT_DSP_DATA_32:		// should we ?
		return 4;
	case SND_FORMAT_DOUBLE:
		return 8;			// correct ?
	case SND_FORMAT_ADPCM_G721:           //(23)	//4bits??
	case SND_FORMAT_ADPCM_G723_3:         //(25)  // should be 3 bits ???
        case SND_FORMAT_ADPCM_G723_5:         //(26) // should be 5 bits ???
        case SND_FORMAT_IMAADPCM_APPL:
        case SND_FORMAT_IMAADPCM_MS:
        case SND_FORMAT_DPCM_FIBO:
        case SND_FORMAT_DPCM_EXP:
		return 0.5;
	case SND_FORMAT_UNSPECIFIED:
        case SND_FORMAT_INDIRECT:
        case SND_FORMAT_NESTED:
        case SND_FORMAT_DSP_CORE:
        case SND_FORMAT_DISPLAY:
        case SND_FORMAT_DSP_COMMANDS:	
	default:				// unknown
                 return 0;
	}
}



/* dont know these ones ..  later !***	
	case SND_FORMAT_MULAW_SQUELCH        (17)

	case SND_FORMAT_DSP_COMMANDS_SAMPLES (22)
	case SND_FORMAT_ADPCM_G721           (23)	//4bits??
	case SND_FORMAT_ADPCM_G722           (24)
	case SND_FORMAT_ADPCM_G723_3         (25)
	case SND_FORMAT_ADPCM_G723_5         (26)

	case SND_FORMAT_AES                  (28)
*/