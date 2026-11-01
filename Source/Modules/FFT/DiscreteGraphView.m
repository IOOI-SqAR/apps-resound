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
#import "DiscreteGraphView.h"
#import <AppKit/AppKit.h>
#include <float.h>

@implementation DiscreteGraphView


- initWithFrame:(NSRect) frameRect
	{
	id returnval=[super initWithFrame:frameRect];
	NSPoint hot_spot;
        id cursor_image;
	
	hot_spot.x=7;hot_spot.y=7;
	
        cursor_image=[[[NSImage alloc] initWithContentsOfFile:
            [[NSBundle bundleForClass:[self class]] pathForImageResource:@"FFTCursor"]] autorelease];
        hot_spot.x=7;hot_spot.y=7;
        // gets full path of SoundViewCursor
        if (cursor_image==nil) printf ("FileController ERROR:  Couldn't Find Cursor Image\n");
        cursor=[[NSCursor alloc]  initWithImage:cursor_image hotSpot:hot_spot];

	reals=NULL;
	x_scale=1;
	reals_size=0;
	plotted_max_values=NULL;
	plotted_min_values=NULL;
	values_size=0;
	draw_format=DISCRETEGRAPHVIEW_FORMAT_HISTOGRAM;
	return returnval;
	}

- (void)dealloc
	{
	if (plotted_max_values) free(plotted_max_values);
	if (plotted_min_values) free(plotted_min_values);
	[super dealloc];
	}

- reloadValues
	{
	/* Assumes there are fewer pixels than reals */
	NSRect bounds=[self bounds];
	int x;

		if (plotted_max_values) free(plotted_max_values);
		if (plotted_min_values) free(plotted_min_values);
		plotted_max_values=NULL; plotted_min_values=NULL;
		if ((floor)(bounds.size.width))
			{
			plotted_max_values=(float*)malloc(sizeof(float)*
				(floor)(bounds.size.width));
			plotted_min_values=(float*)malloc(sizeof(float)*
				(floor)(bounds.size.width));
			values_size=(floor)(bounds.size.width);
			}

	/* set up to extremes */
		for(x=0;x<values_size;x++) 
			{
			plotted_min_values[x]=draw_max_val;
			plotted_max_values[x]=draw_min_val;
			data_max_val=draw_min_val;
			data_min_val=draw_max_val;
			}
			
		if (reals_size==0 || values_size==0)
			{
			for(x=0;x<values_size;x++) 
				plotted_min_values[x]=plotted_max_values[x]=draw_min_val;
			}
		else if (reals_size>values_size) 
			{

			for(x=0;x<reals_size;x++)
				{
				if (plotted_min_values[x*values_size/reals_size]>reals[x])
					plotted_min_values[x*values_size/reals_size]=reals[x];
				if (plotted_max_values[x*values_size/reals_size]<reals[x])
					plotted_max_values[x*values_size/reals_size]=reals[x];
				if (data_min_val > reals[x]) data_min_val=reals[x];
				if (data_max_val < reals[x]) data_max_val=reals[x];
				}
			}
		else
			{
			for(x=0;x<values_size;x++)
				{
				plotted_min_values[x]=reals[x*reals_size/values_size];
				plotted_max_values[x]=reals[x*reals_size/values_size];
				if (data_min_val > reals[x]) data_min_val=reals[x];
				if (data_max_val < reals[x]) data_max_val=reals[x];
				}
			}
	return self;
	}


- (void) drawRect:(NSRect)rects
	{
	int x;
	float plotl,ploth;
	float plotlbound,plothbound;
	NSRect bounds;
	
	[super drawRect:rects];	
	bounds=[self bounds];	
	
	// some checks first...
	
	if ((floor)(bounds.size.width) != values_size)  /* change in size */
		[self reloadValues];

	plotlbound=(stretch_to_min ? data_min_val : draw_min_val);
	plothbound=(stretch_to_max ? data_max_val : draw_max_val);
	if (plothbound-plotlbound==0.0) plothbound=draw_max_val;
	if (plothbound-plotlbound==0.0) plotlbound=draw_min_val;

	[top_field setFloatValue:plothbound];
	[bottom_field setFloatValue:plotlbound];
	
	if (!bounds.size.width||!bounds.size.height||!reals_size) 
		{
		PSsetgray(NSLightGray);
		NSRectFill(bounds);
		return;
		}

	PSsetgray(NSWhite);
	NSRectFill(bounds);

	PSsetgray(NSDarkGray);

	for (x=0;x<values_size;x++)
		{
		plotl=(draw_format==DISCRETEGRAPHVIEW_FORMAT_HISTOGRAM ? 
			draw_min_val :
			(plotted_min_values[x]-plotlbound)/(plothbound-plotlbound)
				*bounds.size.height)+bounds.origin.y;			
		
		ploth=((plotted_max_values[x]-plotlbound)/(plothbound-plotlbound)
				*bounds.size.height)+bounds.origin.y;
		
		if (draw_format==DISCRETEGRAPHVIEW_FORMAT_CENTERED_ON_ZERO)
			{
			if (plotted_max_values[x]<0) 
				ploth=bounds.origin.y+bounds.size.height/2;
			if (plotted_min_values[x]>0) 
				plotl=bounds.origin.y+bounds.size.height/2;
			}

		if (x==0) PSmoveto(bounds.origin.x+x,plotl);

		PSlineto(bounds.origin.x+x,ploth);
		PSlineto(bounds.origin.x+x,plotl);
		}
	PSstroke();
	}


- setReals:(float*) r size:(int) s
	{
	reals=r; reals_size=s;
	[self reloadValues];
	return self;
	}


- setTo:(float)maxVal:(float)minVal:(BOOL)stretchToMax:
	(BOOL)stretchToMin:(int)xScale:(int)format;
	{
	x_scale=xScale;
	draw_max_val=maxVal;
	draw_min_val=minVal;
	stretch_to_max=stretchToMax; 
	stretch_to_min=stretchToMin;
	draw_format=format;
	return self;
	}

- (void)resetCursorRects
{   
   if (x_delegate&&y_delegate)
        [self addCursorRect:[self visibleRect] cursor:cursor];
}




- (float) floatValue {return tmp_f;}
- (int) intValue {return tmp_i;}

- doMouse:(NSEvent*)theEvent
	{
	NSRect bounds=[self bounds];
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if ([x_delegate respondsToSelector:@selector(takeFloatValueFrom:)])
		{
		if (bounds.size.width)
			tmp_i=floor(((float)loc.x)/
			((float)bounds.size.width)*((float)x_scale));
		else tmp_i=0;
		[x_delegate takeIntValueFrom:self];
		}
	if ([y_delegate respondsToSelector:@selector(takeFloatValueFrom:)])
		{
		if (bounds.size.height)
			{ tmp_f=((float)floor(loc.y))/((float)bounds.size.height)*
				((stretch_to_max&&reals_size&&values_size ? 
					data_max_val : draw_max_val) - 
				 (stretch_to_min &&reals_size&&values_size? 
				 	data_min_val : draw_min_val)) +
				(stretch_to_min &&reals_size&&values_size? 	
					data_min_val : draw_min_val); }
		else tmp_f=0.0;
		[y_delegate takeFloatValueFrom:self];
		}
	return self;
	}


- (void) mouseDown:(NSEvent*) theEvent
	{
	// Stolen from Next Concepts, chapter 7
	   /* register int   inside;
	    int            shouldLoop = YES;
	    int            oldMask;
	    NXEvent       *nextEvent;
	    NSRect	 visible;
		NSPoint		loc;*/



                BOOL keepOn = YES;
                BOOL isInside = YES;
                NSPoint mouseLoc;

                [self doMouse:theEvent];
		do {
                     mouseLoc = [self convertPoint:[theEvent locationInWindow]
			fromView:nil];
                     isInside = [self mouse:mouseLoc inRect:[self bounds]];

                     switch ([theEvent type]) {
                        case NSLeftMouseDragged:
                        	[self doMouse:theEvent];
                                break;
                        case NSLeftMouseUp:
                        	[self doMouse:theEvent];
                                keepOn = NO;
                                break;
                        default:
                                /* Ignore any other kind of event. */
                                break;
                    }

                    theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                            NSLeftMouseDraggedMask];

                 }while (keepOn);

                return;






/*
	loc=[theEvent locationInWindow];
	//[self convertPoint:&loc fromView:nil];
	[self doMouse:theEvent];
	
	oldMask = [window addToEventMask:NX_LMOUSEDRAGGEDMASK];
    while (shouldLoop) 
		{
        nextEvent = [NXApp getNextEvent:(NX_LMOUSEUPMASK |
                                         NX_LMOUSEDRAGGEDMASK)];
		loc=nextEvent->location;
		[self convertPoint:&loc fromView:nil];
        [self getVisibleRect:&visible];
		inside = NXMouseInRect(&loc,&visible,NO);
		switch (nextEvent->type)
			{
			case NX_MOUSEUP:
				shouldLoop = NO;
				if (inside) [self doMouse:theEvent];
            	break;
        	case NX_MOUSEDRAGGED:
            	if (inside) [self doMouse:theEvent];
            	break;
        	default:
            	break;
			}
        }
    [window setEventMask:oldMask];
    return self;*/

	}
	

- useCursor:x_d:y_d
	{
	x_delegate=x_d;
	y_delegate=y_d;
	/*
	[[self window] set (x_d&&y_d) [[self window] addToEventMask:NSLeftMouseDraggedMask];
	else [[self window] addToEventMask:NSLeftMouseDraggedMask];
	*/
	[[self window] invalidateCursorRectsForView:self];
	return self;
	}

@end
