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

@interface ZoomInspector:NSObject
    {
    id  fileController;
    id  inspectorController;
    id  zoomSlider;						// IO objects
    id  zoomField;
    id  reductionField;
    id  inspector;
    id  continuous_button;
    
    int windowsLoaded;
    }

- init;
- getInspector:sender;
- update:sender;  /* update inspector; returns nil if can't */
- setContinuousZoom: (BOOL) ZoomOn;		// set the zoom to continuous/non-cont.
- toggleContinuousZoom:sender;


- takeFloatValueFromMe:sender;	         // Sent from ZoomSlider
- zoomToSelection:sender;		// Sent from ZoomToSelection Button
- zoomAllIn:sender;
- zoomAllOut:sender;
- zoomInOneReduction:sender;
- zoomOutOneReduction:sender;
- findSelection:sender;			// scrolls to selection if any

- zoomChanged:sender; // backward compatible method: calls update:sender

@end
