/*
Copyright (c) 1998 by Sean Luke (hereafter referred to as "the Author")
seanl@cs.umd.edu     http://www.cs.umd.edu/users/seanl/

Permission to use, copy, modify, and distribute the source code and
related materials of this software for any purpose and without fee is
hereby granted, provided the Author's name shall not be used in
advertising or publicity pertaining to this material without the
specific, prior written permission of the Author, acknowledgement
of the author appears prominently in the distributed documentation
of any software application derived from this source code, and this
copyright notice appears in all derived source copies.  SEAN LUKE MAKES
NO REPRESENTATIONS ABOUT THE ACCURACY OR SUITABILITY OF THIS MATERIAL
FOR ANY PURPOSE.  IT IS PROVIDED "AS IS", WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES.

*/
#include <limits.h>
#include <float.h>
#import "FFTController.h"
#import "ModuleSound.h"
#import "ModuleSoundView.h"

#define __PI__ 3.141592653589793

@implementation FFTController

- drawFFT:(Sound*) this_sound:(SoundView*)
			this_soundview: (int)start_sample:(int)number_samples
	{
	int x;
	float* f;
	float min_db;
	char* samples;
	
	if ((this_sound==nil)
		||start_sample+number_samples>[this_sound sampleCount]||!number_samples)
		{
		NSRunAlertPanel(@"FFT", 
		@"There is no selected sound on which to perform this operation", 
		@"Okay",nil,nil);
		return nil;
		}

	if ([this_sound dataFormat]!=SND_FORMAT_FLOAT &&
		[this_sound dataFormat]!=SND_FORMAT_DOUBLE &&
		[this_sound dataFormat]!=SND_FORMAT_LINEAR_8 &&
		[this_sound dataFormat]!=SND_FORMAT_LINEAR_16 &&
		[this_sound dataFormat]!=SND_FORMAT_MULAW_8)
		{
		if (NSRunAlertPanel(@"FFT",
			@"Convert this sound to mono, 16-bit linear, 44.1 KHz to perform this operation?",
			@"Okay",@"Cancel",nil)==NSAlertDefaultReturn)
			{
			if ([this_soundview convertToFormat: SND_FORMAT_LINEAR_16 
							samplingRate:   SND_RATE_HIGH 
							channelCount:   1]!= SND_ERR_NONE)
				{
				NSRunAlertPanel(@"FFT", 
				@"Could not convert sound", 
				@"Okay",nil,nil);
				return nil;
				}
			}
		else return nil;
		}
	else if ([this_sound channelCount]!=1 || [this_sound samplingRate]!=SND_RATE_HIGH)
		{
		if (NSRunAlertPanel(@"FFT",
			@"Convert this sound to mono, 44.1 KHz to perform this operation?",
			@"Okay",@"Cancel",nil)==NSAlertDefaultReturn)
			{
			if ([this_soundview convertToFormat: [this_sound dataFormat] 
							samplingRate:   SND_RATE_HIGH 
							channelCount:   1]!= SND_ERR_NONE)
				{
				NSRunAlertPanel(@"FFT", 
				@"Could not convert sound", 
				@"Okay",nil,nil);
				return nil;
				}
			}
		else return nil;
		}
	
	if ([this_sound needsCompacting]) [this_sound compactSamples];
	
	samples=[this_sound data];
	
	SNDSwapSoundToHost
		((void*)samples, (void*)samples, [this_sound sampleCount], 
			[this_sound channelCount], [this_sound dataFormat]);
		
	n=[Sound nextPositivePowerOfTwo:number_samples];
	f=(float*)malloc(sizeof(float)*n*2);

	[Sound performFFTFromSoundData:samples:start_sample:number_samples:
		[this_sound dataFormat]:[this_sound channelCount] 
		toFFTData:f:n];
	
	SNDSwapHostToSound
		((void*)samples, (void*)samples, [this_sound sampleCount], 
			[this_sound channelCount], [this_sound dataFormat]);	

	if (f1) free(f1);
	if (f2) free(f2);
	if (p1) free(p1);
	f1=(float*)malloc(sizeof(float)*n/2);
	f2=(float*)malloc(sizeof(float)*n/2);
	p1=(float*)malloc(sizeof(float)*n/2);

	for (x=0;x<n/2;x++)
		{
		f1[x]=f[x*2+n];									/* Linear */
		f2[x]=20 * log(f[x*2+n] < 0 ? -(FLT_MAX) : 
						(f[x*2+n]>1 ? 1 : f[x*2+n]));		/* Decibels */
		p1[x]=f[x*2+n+1];
		}
	free(f);

	min_db=0.00001;  // some tiny positive number
	for(x=0;x<n/2;x++) if (f2[x]<min_db) min_db=f2[x];

	[minimumdbfield setFloatValue:min_db];

#define DEFAULT_MINIMUM_DB 30

	if (islinear)
		{
		[freqview setTo:1.0:0.0:YES:NO:22050:DISCRETEGRAPHVIEW_FORMAT_HISTOGRAM];
		[freqview setReals:f1 size:n/2];
		[freqview display];
		}
	else
		{
		[freqview setTo:0.0:
			([minimumdbfield floatValue] < 0 ? [minimumdbfield floatValue] : DEFAULT_MINIMUM_DB)
		:YES:NO:22050:DISCRETEGRAPHVIEW_FORMAT_HISTOGRAM];
		[freqview setReals:f2 size:n/2];
		[freqview display];
		}
		
	[phasview setTo:__PI__:-__PI__:NO:NO:22050:
		DISCRETEGRAPHVIEW_FORMAT_CENTERED_ON_ZERO];
	[phasview setReals:p1 size:n/2];
	[phasview display];

	return self;
	}

- redrawGraphs:sender
	{
	if (f1&&f2)
		{
		if (islinear)
			{
			[freqview setTo:1.0:0.0:YES:NO:22050:DISCRETEGRAPHVIEW_FORMAT_HISTOGRAM];
			[freqview setReals:f1 size:n/2];
			[freqview display];
			}
		else	
			{
			[freqview setTo:0.0:
				([minimumdbfield floatValue] < 0 ?  
					[minimumdbfield floatValue] : DEFAULT_MINIMUM_DB) 
					:YES:NO:22050:DISCRETEGRAPHVIEW_FORMAT_HISTOGRAM];
			[freqview setReals:f2 size:n/2];
			[freqview display];
			}
		
		[phasview setTo:__PI__:-__PI__:NO:NO:22050:
			DISCRETEGRAPHVIEW_FORMAT_CENTERED_ON_ZERO];
		[phasview setReals:p1 size:n/2];
		[phasview display];
		}
	return self;
	}

- toggleLinearAndDecibel:sender
	{
	islinear=![decibelButton intValue];
	return [self redrawGraphs:self];
	}

- setDelegates:x:y
	{
	[freqview useCursor:x:y];
	return self;
	}

- init { f1=NULL; f2=NULL; p1=NULL; return [super init]; }

- (void) dealloc
	{
	if (f1) free(f1);
	if (f2) free(f2);
	if (p1) free(p1);
	[super dealloc];
	}

@end
