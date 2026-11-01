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


/*
Unlike most other Resound objects, this object has hangovers from
days yore that give it weird capitalization (Methods, classes, and
instance variables are *all* capitalized).  This was from olden times
when I didn't know better and was a young'n ObjC programmer.  But I don't
really want to convert this over; I've converted enough methods over by
now, and it also requires re-hooking up all the IB connections.  If you
want to do this, feel free.
*/


#import "Module.h"

@interface FilterModule:Module
{
    id	Sliders;
	id  PercentDone;
	id  Position;
	id  Amplitude;
	id  EchoPercentDone;
	id  FilterPanel;
	id  EchoFilterPanel;
	id  recursive;
	
	int WindowLoaded;
}

- init;

- LoadFilterPanel:sender;
- LoadEchoFilterPanel:sender;
//- Sum:sender;
- Zero:sender;
- Difference:sender;
- Apply:sender;
- ApplyEcho:sender;
- Normal:sender;
- Echo:sender;
- Halve:sender;
- Double:sender;
- MultiEcho:sender;
- (int) Max;					// called internally.
- (int) Min;					// called internally.

@end
