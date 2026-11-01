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

float formatSampleSize(short format);

// Formats used for framework 

// formats as defined for .snd and .au sounds:

#define SUN_ULAW	1			/* u-law encoding */
#define SUN_LIN_8	2			/* Linear 8 bits */
#define SUN_LIN_16	3			/* Linear 16 bits */
#define SUN_LIN_24	4			/* Linear 24 bits */
#define SUN_LIN_32	5			/* Linear 32 bits */
#define SUN_FLOAT	6			/* IEEE FP 32 bits */
#define SUN_DOUBLE	7			/* IEEE FP 64 bits */
#define SUN_G721	23			/* CCITT G.721 4-bits ADPCM */
#define SUN_G723_3	25			/* CCITT G.723 3-bits ADPCM */
#define SUN_G723_5	26			/* CCITT G.723 5-bits ADPCM */

/*
 * NeXT data format codes. User-defined formats should be greater than 255.
 * Negative format numbers are reserved.
 */
#define SND_FORMAT_UNSPECIFIED          (0)
#define SND_FORMAT_MULAW_8              (1)
#define SND_FORMAT_LINEAR_8             (2)
#define SND_FORMAT_LINEAR_16            (3)
#define SND_FORMAT_LINEAR_24            (4)
#define SND_FORMAT_LINEAR_32            (5)
#define SND_FORMAT_FLOAT                (6)
#define SND_FORMAT_DOUBLE               (7)
#define SND_FORMAT_INDIRECT             (8)
#define SND_FORMAT_NESTED               (9)
#define SND_FORMAT_DSP_CORE             (10)
#define SND_FORMAT_DSP_DATA_8           (11)
#define SND_FORMAT_DSP_DATA_16          (12)
#define SND_FORMAT_DSP_DATA_24          (13)
#define SND_FORMAT_DSP_DATA_32          (14)
#define SND_FORMAT_DISPLAY              (16)
#define SND_FORMAT_MULAW_SQUELCH        (17)
#define SND_FORMAT_EMPHASIZED           (18)
#define SND_FORMAT_COMPRESSED           (19)
#define SND_FORMAT_COMPRESSED_EMPHASIZED (20)
#define SND_FORMAT_DSP_COMMANDS         (21)
#define SND_FORMAT_DSP_COMMANDS_SAMPLES (22)
#define SND_FORMAT_ADPCM_G721           (23)
#define SND_FORMAT_ADPCM_G722           (24)
#define SND_FORMAT_ADPCM_G723_3         (25)
#define SND_FORMAT_ADPCM_G723_5         (26)
#define SND_FORMAT_ALAW_8               (27)
#define SND_FORMAT_AES                  (28)
#define SND_FORMAT_DELTA_MULAW_8	(29)

//
#define kCustomCodebase 1000

#define SND_FORMAT_IMAADPCM_APPL        kCustomCodebase+1
#define SND_FORMAT_IMAADPCM_MS        kCustomCodebase+2
#define SND_FORMAT_DPCM_FIBO		kCustomCodebase+3
#define SND_FORMAT_DPCM_EXP		kCustomCodebase+4
