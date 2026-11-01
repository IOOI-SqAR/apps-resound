/*

MiscVolumeLight
 Version 2.0
 Copyright (c) 1995 by Sean Luke
 OpenStep / Rhapsody port
 Copyright (c) 1998 by Jerome Genest
 Donated to the MiscKit

 Permission to use, copy, modify, and distribute this material
 for any purpose and without fee, under the restrictions as noted
 in the MiscKit copyright notice, is hereby granted, provided that
 the MiscKit copyright notice and this permission notice
 appear in all source copies, and that the authors names shall not
 be used in advertising or publicity pertaining to this
 material without the specific, prior written permission
 of the author.  SEAN O. LUKE AMD JEROME GENEST  MAKE NO REPRESENTATIONS 
 ABOUT THE ACCURACY OR SUITABILITY OF THIS MATERIAL FOR ANY PURPOSE.
 IT IS PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.

 */

#import "MiscVolumeLight.h"
#import <stdio.h>

@implementation MiscVolumeLight

- (void)drawRect:(NSRect)rects
	{
	int just_erase=0;
	float left,right;
	NSRect backgroundRect=[self bounds];
	NSRect theBounds = [self bounds];

	
	//printf ("Displaying\n");
	
	if ([delegate respondsToSelector:@selector(meterWillUpdate:)])
		[delegate meterWillUpdate:self];

//	if (![window isVisible]) return self;		// no window to draw in.
	
	//printf ("Window Visible\n");
	
	//if (![window isVisible]) return NULL;		// no window to draw in.
	// the above has been turned off because when loading Resound,
	// the sound meter wouldn't display until a sound was being played
	// or recorded!
	
	
	// first to check to see if the sound lock is current
	////printf ("Meter\n");
	if (sound!=NULL)
		{
		int status=NX_SoundStopped;
		id actual_sound=NULL;			// quiets compiler complaints
		
		//printf ("Sound ain't Null\n");
		
		if ([sound isKindOfClass:[Sound class]]) 
			{actual_sound=sound;}
		else if ([sound isKindOfClass:[SoundView class]])
			{actual_sound=[sound soundBeingProcessed];}
		status=[actual_sound status];
		if (status==NX_SoundStopped||
			status==NX_SoundInitialized||
			status==NX_SoundFreed) 
		{just_erase=1;}
			
		// Then modify the meter to match the sound	
		
		else if (status==NX_SoundRecordingPaused||
				 status==NX_SoundRecording||
				 status==NX_SoundRecordingPending)
		{[self setToInput];}
		
		else if (status==NX_SoundPlayingPaused||
				 status==NX_SoundPlaying||
				 status==NX_SoundPlayingPending)
		{[self setToOutput];}
		
		if ([actual_sound channelCount]>1)
			{[self setStereo];}
		else {[self setMono];}
		}
	

	
	
	
	if (bezeled)
		{
		backgroundRect.origin.x		+=VOLUMEMETER_BACKGROUND_INSET; 
		backgroundRect.size.width	-=VOLUMEMETER_BACKGROUND_INSET*2;
		backgroundRect.origin.y		+=VOLUMEMETER_BACKGROUND_INSET; 
		backgroundRect.size.height	-=VOLUMEMETER_BACKGROUND_INSET*2;
		}

	if (!VOLUMEMETER_can_draw(&theBounds)) return;	// can't draw
	//printf("Big enough\n");
	if (bezeled) NSDrawGrayBezel(theBounds , theBounds);

	if (running&&!just_erase)
		{
		//printf ("DRAWING!\n");
		left=0;right=0;
		
		if (input&&input_device!=NULL) 
			[input_device getPeakLeft:&left right:&right];
		
		if ((!input)&&output_device!=NULL)
			[output_device getPeakLeft:&left right:&right];
			
		if (left>1) left=1; if (right>1) right=1;
			// occasionally a NeXTSTEP bug returns values larger than 1!
		
		PSsetgray((left+right)/2.0);
		NSRectFill(backgroundRect);
		}
	just_erase=0;
	PSWait();
	if ([delegate respondsToSelector:@selector(meterDidUpdate:)])
		[delegate meterDidUpdate:self];
}

- (NSString *)inspectorClassName
        {
	return @"MiscVolumeLightInspector";
        }
@end