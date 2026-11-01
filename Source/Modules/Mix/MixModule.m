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

	#import "MixModule.h"
	#import <SoundKit/SoundKit.h>
	#import <AppKit/AppKit.h>

@interface SoundView(Mix)
- mix:(id)moduleController;
@end



	@implementation MixModule

	-init
		{
		id returnVal=[super init];
		
		ModuleMenuNode* mixNode=[[ModuleMenuNode alloc] initLeafNode:
			@"Mix In":self:@selector(mix:)];
		
		[rootModuleMenuNode addSubmenu: mixNode];
		
		return returnVal;
		}
		
	- mix:sender
		{
                NSMutableArray* array=[NSMutableArray arrayWithCapacity:1];
		SoundView* cview=[moduleController currentSoundView];
#ifdef PASTE_BUG
                id pb=[NSPasteboard generalPasteboard];
#endif

                /* First, determine if we can mix or not */
                [array addObject:NXSoundPboardType];

#ifdef PASTE_BUG
                if (![[pb availableTypeFromArray:array] isEqualToString:NXSoundPboardType])
			{
			return nil;
			}
		else if (![moduleController stillExists])
			{
			[moduleController invalidatePasteboard];
	
			/* Now, don't paste */
			return nil;
			}
#endif	
		// we can paste!	

		[cview mix:moduleController];
		[moduleController soundChanged];
		return self;
		}	

	@end


@implementation SoundView(Mix)


- mix:(id)moduleController
	{
	int size, selection;
	int x;
	Sound* s;
	unsigned char* data1;
	unsigned char* data2;
	int ch,sa,df;
	int num_bytes=1;

	id tmpsoundview;
	id tmpscrollview;
	NSWindow* tmpwindow;
	NSRect tmprect;
	
        /* Compact the sound--ouch! */

        if ([[self sound] needsCompacting]) [[self sound] compactSamples];
        



	/* First, we need a sound from the pasteboard.  Rhapsody has made
	   this difficult because initFromPasteboard doesn't work any more!
	   And if we use SoundView, we get bitten by the cursor bug.
           So we have no choice but to use ResoundMiscSoundView, which is
	   against the rules. :-(  So I've included ResoundMiscSoundView
	   and MiscSoundView here.  There's probably got to be a better way
	   to do this (maybe a ModuleProtocol option that returns a fresh
	   one for ya). */
        s=[[[Sound alloc] init] autorelease];
/*	tmprect.size.width=10; tmprect.size.height=10;
	tmprect.origin.x=0; tmprect.origin.y=0; // make something up
	tmpwindow=[[[NSWindow alloc] initWithContentRect:tmprect
		styleMask:0 backing:NSBackingStoreBuffered defer:NO] autorelease];
        tmpscrollview=[[[NSScrollView alloc] initWithFrame:tmprect] autorelease];
	tmpsoundview=[[[ResoundMiscSoundView alloc] initWithFrame:tmprect] autorelease];

        [tmpsoundview setIgnoreShowAndHideCursor:YES];
        [tmpwindow setContentView:tmpscrollview];
        [tmpscrollview setDocumentView:tmpsoundview];
        [tmpsoundview setIgnoreShowAndHideCursor:NO];*/
        [moduleController newWindow:&tmpwindow:&tmpscrollview:&tmpsoundview];

        [(SoundView*)tmpsoundview setSound:s];	// TypeCast for OS X server
        [tmpsoundview readSelectionFromPasteboard: [NSPasteboard generalPasteboard]];

	[s 	convertToFormat:[[self sound] dataFormat] 
		samplingRate:[[self sound] samplingRate]
		channelCount:[[self sound] channelCount]];
	
	/* determine size and selection */
	
	[self getSelection:&selection size:&size];
	if (size==0) size=[[self sound] sampleCount]-selection;  // to end of sound
	if (size>[s sampleCount]) size=[s sampleCount];		// whittle to min sound
	if (size==0) return self;			// huh?  nothing to mix into
	if (selection<0||selection>=[[self sound] sampleCount]) return self; // huh?
	

	/* load the data */
	
	data1=(unsigned char*)[s data];
	data2=(unsigned char*)[[self sound] data];
	
	ch=[s channelCount]; sa=[s sampleCount];  df=[s dataFormat];
	SNDSwapSoundToHost
			((void*)data1, (void*)data1, sa, ch, df);

	ch=[[self sound] channelCount];
	sa=[[self sound] sampleCount]; 
	df=[[self sound] dataFormat];
	SNDSwapSoundToHost
			((void*)data2, (void*)data2, sa, ch, df);

	num_bytes=ch;  // channels makes all the difference!
	
	// df is data format.  If the data format is SND_FORMAT_MULAW_8,
	// then we need to convert the format first.  If it's something
	// weird, then we have to refuse mixing.
	

	switch([[self sound] dataFormat])
		{
		case SND_FORMAT_MULAW_8: 
			{
			char* d1=(char*)data1;
			char* d2=(char*)data2;
			for (x=selection*num_bytes;
				 x<selection*num_bytes+size*num_bytes;
				 x++)
				d2[x]=SNDMulaw(
					SNDiMulaw(d2[x])+
					SNDiMulaw(d1[x-selection*num_bytes]));
			} break;
		case SND_FORMAT_LINEAR_8:
			{
			char* d1=(char*)data1;
			char* d2=(char*)data2;
			for (x=selection*num_bytes;
				 x<selection*num_bytes+size*num_bytes;
				 x++)
				d2[x]+=d1[x-selection*num_bytes];
			} break;
		case SND_FORMAT_LINEAR_16:
			{
			signed short* d1=(signed short*)data1;
			signed short* d2=(signed short*)data2;
			for (x=selection*num_bytes;
				 x<selection*num_bytes+size*num_bytes;
				 x++)
				d2[x]+=d1[x-selection*num_bytes];
			} break;
		case SND_FORMAT_FLOAT:
			{
			float* d1=(float*)data1;
			float* d2=(float*)data2;
			for (x=selection*num_bytes;
				 x<selection*num_bytes+size*num_bytes;
				 x++)
				d2[x]+=d1[x-selection*num_bytes];
			} break;
		case SND_FORMAT_DOUBLE:
			{
			double* d1=(double*)data1;
			double* d2=(double*)data2;
			for (x=selection*num_bytes;
				 x<selection*num_bytes+size*num_bytes;
				 x++)
				d2[x]+=d1[x-selection*num_bytes];
			} break;
		default: 	
			NSRunAlertPanel(@"Mix",
				@"Can't mix this format.",@"Oops",nil,nil);
 			break;
		}

	ch=[s channelCount]; sa=[s sampleCount]; 
		df=[s dataFormat];
	SNDSwapHostToSound
			((void*)data1, (void*)data1, sa, ch, df);

	ch=[[self sound] channelCount]; sa=[[self sound] sampleCount]; 
		df=[[self sound] dataFormat];
	SNDSwapHostToSound
			((void*)data2, (void*)data2, sa, ch, df);

	return self;
	}


@end
