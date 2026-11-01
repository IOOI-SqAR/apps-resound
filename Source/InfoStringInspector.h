/* DONE */
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface InfoStringInspector:NSObject
    {
    id  inspectorController;
    id  fileController;

    id	infoString;			    // the text object 
    NSWindow*  infoWindow;
    int infoWindowLoaded;
    
    id  inspector;
    }

- init;
- noWindow;					// No sound is currently open
- update:sender;		 // Sound is open, update info for sound ThisSound.
- getInspector:sender;
- okay:sender;
- revert:sender;

@end
