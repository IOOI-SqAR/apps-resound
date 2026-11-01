/*

MiscSoundViewRuler
Version 2.0
Copyright (c) 1998 by Jerome Genest
parts by Sean Luke Copyright(c)  1995
Donated to the MiscKit

Permission to use, copy, modify, and distribute this material
for any purpose and without fee, under the restrictions as noted
in the MiscKit copyright notice, is hereby granted, provided that
the MiscKit copyright notice and this permission notice
appear in all source copies, and that the authors names shall not
be used in advertising or publicity pertaining to this
material without the specific, prior written permission
of the author.  JEROME GENEST  AND SEAN O. LUKE MAKES NO REPRESENTATIONS 
ABOUT THE ACCURACY OR SUITABILITY OF THIS MATERIAL FOR ANY PURPOSE.
IT IS PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.

*/

#import <AppKit/AppKit.h>
#import "MiscSoundView.h"

@interface MiscSoundViewRuler : NSRulerView
{
float play_mark;				// Current play mark position	
float old_play_mark;	

// Temporary Update
BOOL only_change_play_mark;			// On next display, only update
}						// the play mark

- initWithFrame:(NSRect)frameRect;

- (void)drawHashMarksAndLabelsInRect:(NSRect)rects;	// Ticks and labels drawing

-setPlayMark:(int)theMark;			// Sets the play mark position
-(BOOL)onlyChangePlayMark;			// Return if next update is limited
						// to the play mark. 
						// Used by the MiscSoundView

- (void)setRuleThickness:(float)thickness;	// Overridden to ensure a minimal 						// thickness

@end
