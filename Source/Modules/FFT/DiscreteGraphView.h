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
#import <AppKit/AppKit.h>

#define DISCRETEGRAPHVIEW_FORMAT_MINMAX 0
#define DISCRETEGRAPHVIEW_FORMAT_HISTOGRAM 1
#define DISCRETEGRAPHVIEW_FORMAT_CENTERED_ON_ZERO 3

@interface DiscreteGraphView:NSView
	{
		float draw_max_val;
		float draw_min_val;
		float data_max_val;
		float data_min_val;

		float*	reals;
		int		reals_size;
		
		float*	plotted_max_values;
		float*  plotted_min_values;
		int values_size;		

		BOOL	stretch_to_max;		// scale so actual max value fills view
		BOOL	stretch_to_min;
		
		id		x_delegate;
		id		y_delegate;
		id		cursor;

		id		top_field;
		id		bottom_field;
		
		int		x_scale;
		int 	draw_format;
		
		float 	tmp_f;
		float 	tmp_i;
	}

- initWithFrame:(NSRect)frameRect;
- setReals:(float*) r size:(int)s;
- (void)drawRect:(NSRect)rect;
- setTo:(float)maxVal:(float)minVal:(BOOL)stretchToMax:(BOOL)stretchToMin:
	(int)xScale:(int)format;
- useCursor:x_d:y_d;		// use cursor and inform delegates x and y using
							// delegate message whenever user clicked
							// in view.  Disable using Cursor by setting
							// x and y to NULL.
- (float) floatValue;
- (int) intValue;
- (void) dealloc;

@end


/* Delegate:
	- takeFloatValueFrom:sender
*/

