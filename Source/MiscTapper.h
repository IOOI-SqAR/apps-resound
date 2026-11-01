/*

 MiscTapper
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

#import <AppKit/AppKit.h>
#import <SoundKit/SoundKit.h> 


@interface MiscTapper:NSObject <NSCoding>

{
	NXSoundIn*		tapper_device;
	NXRecordStream*		tapper_stream;
	NSTimer*		teNum;
	int			tapper_load;
	int			running;
}

- init;
			
- (void)dealloc;

/* Interface builder seems to need them ! */

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

- (void)run:(id)sender;			// Starts or resumes tapping
- (void)stop:(id)sender;		// Suspends tapping
- (void)tapper_timer: (id) theTimer;	// Called  when the NSTimer is fired
@end