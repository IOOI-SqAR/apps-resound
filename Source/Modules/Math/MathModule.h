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
MathModule
For Resound 3.0
Sean Luke

An example math transform module, including reversing, inverting,
abs, volume and vertical shifting.  This module includes a custom
nib file and several menu additions to Resound's Modules menu.
*/

#import "Module.h"

@interface MathModule:Module
{
	BOOL nib_loaded;		// panels have been loaded
	id	multiplyPanel;
	id	percentChangeScroller;
	id	percentChangeField;
	id	shiftPanel;
	id	shiftSliderValue;
}

- init;
- reverseIt:sender;			// reverse, but keep channels correct
- invertIt:sender;			// invert
- absIt:sender;				// perform absolute value
- shiftIt:sender;			// changing vertical position
- multiplyIt:sender;		// changing volume
- showShiftPanel:sender;
- showMultiplyPanel:sender;
- halve:sender;
- double:sender;
- maximize:sender;

@end
