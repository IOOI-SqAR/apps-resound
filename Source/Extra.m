
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

Extra.[h|m]
Sean Luke
April 28, 1998

This object's function is to provide simple additional functionality
that doesn't *have* to be in FileController.  In general, the object
should remain small, and if the functionality here is getting big,
chunks of it should get spun off into their own objects.

*/

#import <AppKit/AppKit.h>
#import "Extra.h"

@implementation Extra

/* Some simple methods for opening Resound's web page in OmniWeb */

- (void) openURLInOmniWeb:(NSString*) urlString
{
    NSPasteboard *pasteboard  = [NSPasteboard pasteboardWithUniqueName];

    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:urlString forType:NSStringPboardType];
    if (!NSPerformService(@"OmniWeb/Open URL", pasteboard))
	{
        NSRunAlertPanel(@"Resound's Home Page",
		[NSString stringWithFormat:@"Resound was not able to tell OmniWeb to load this page.  You can open the page yourself at @",urlString],
		@"Oh",nil,nil);
	}
}

- openResoundHomePage:sender
        {
        [self openURLInOmniWeb:@"http://www.cs.umd.edu/users/seanl/Resound/"];
	return self;
	}

- openResoundOnlineHelp:sender
        {
        [self openURLInOmniWeb:[NSString stringWithFormat:@"file:%@/Resources/Documentation/",
		[[NSBundle mainBundle] bundlePath],nil]];
        return self;
        }

@end

