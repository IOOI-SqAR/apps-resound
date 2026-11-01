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

#import "MiscTapper.h"
#import <stdio.h>
#import <objc/objc-runtime.h>



#define	TAPPER_BUFFER_SIZE	65536
	// buffer size to deliver to stream reading in from microphone,
	// 64K of sound, or enough for about 8 seconds of CODEC.
#define TAPPER_TAG 679201341		
	// if this object pauses, try changing this arbitrary tag
#define	TAPPER_REFRESH	.1
	// fraction of a second tapper checks for finished data.


@implementation MiscTapper
	
- _update					// Private
	{
	if (tapper_load) 
		{
		tapper_load=0;
		[tapper_stream recordSize:TAPPER_BUFFER_SIZE tag:TAPPER_TAG];
		}
	return self;	
	}	
	
- init
	{
	id returnval;
	returnval=[super init];
	tapper_device=[[NXSoundIn alloc] init];
	tapper_stream=[[NXRecordStream alloc] initOnDevice:tapper_device];
	[tapper_stream setDelegate:self];
	return returnval;
	}

- (void)stop:(id)sender
	{
	running=0;
	if (teNum) [teNum invalidate]; [teNum release];;
	teNum=0;
	[tapper_stream deactivate];
}
	
- (id)initWithCoder:(NSCoder *)aDecoder
{
tapper_device=[[NXSoundIn alloc] init];
tapper_stream=[[NXRecordStream alloc] initOnDevice:tapper_device];
[tapper_stream setDelegate:self];
return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;	
{
}

- (void)run:(id)sender
	{
	if (running) return ;//self;	// Already running.  Why re-run?
	tapper_load=1;			// This ensures that the tapper is
					// ready to accept stream info.
					// When deactivated a stream may not
					// have finished recording, so
					// tapper_load could possibly be 0!
	running=1;
	[tapper_stream activate];
	if (teNum) 
		{
		[teNum invalidate]; 
		[teNum release];
		}

	teNum = [[NSTimer timerWithTimeInterval:TAPPER_REFRESH 
					 target:self 
				       selector:@selector(tapper_timer:) 
				       userInfo:(void*) self 
					repeats:YES] retain];
           [[NSRunLoop currentRunLoop] addTimer:teNum forMode:NSDefaultRunLoopMode];  
						
	//return self;
	}


- (void)dealloc
	{
	running=0;						// just in case
	[tapper_stream deactivate];
	if (teNum) [teNum invalidate]; [teNum release];;
	teNum=0;
	[tapper_stream release];
	[tapper_device release];
	{ [super dealloc]; return; };
	}

- (void)soundStream:sender didRecordData:(void*) data 
	size:(unsigned int) numBytes forBuffer:(int)tag
	{
	vm_deallocate(task_self(),(vm_address_t) data,(vm_size_t) numBytes);
	tapper_load=1;
	}
	
// Called periodically when the NSTimer is fired

- (void) tapper_timer: (id) theTimer
        {
        [self _update];
        }	
@end







