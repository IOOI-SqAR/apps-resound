/* Done */

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

@interface InspectorManager:NSObject
    {
    id inspector;
    id inspectorView;

    id fileController;    

    id nothingInspector;	// inspector window with "no inspector" message 
    id popUpListButton;		// the button that triggers the pop up list
    
    NSView* attributesView;
    NSView* zoomView;
    NSView* selectionView;
    NSView* marksView;
    NSView* infoStringView;
    NSView* nothingView;
    
    id attributesInspector;
    id zoomInspector;
    id selectionInspector;
    id infoStringInspector;
    id marksInspector;

    BOOL inspectorsLoaded;
    BOOL inspectorOn;
    NSView* currentView;			// the view chosen by the pop-up list,
    NSView* contentView;			// as opposed to the content view of the
                                    // window, which could be NothingView!
    }


- init;
- displayInspector:sender;
- displayAttributes:sender;				// Item 1
- displaySelection:sender;				// Item 2
- displayZoom:sender;					// Item 3
- displayMarks:sender;					// Item 4
- displayInfoString:sender;				// Item 5

- update;				    // Update Information if displayed
- turnOnInspector;			    // Turn On Inspector if displayed
- turnOffInspector;			    // Turn Off Inspector if displayed

- (BOOL) infoShowing;
- (BOOL) zoomShowing;
- (BOOL) selectionShowing;
- (BOOL) marksShowing;
- (BOOL) infoStringShowing;

- inspectorWindow;


@end
