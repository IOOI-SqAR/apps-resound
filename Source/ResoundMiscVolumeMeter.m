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
/****************************************************************************

  ResoundMiscVolumeMeter.[h|m]
  Sean Luke
  
  ResoundMiscVolumeMeter overrides the drawSelf method of MiscVolumeMeter to
  be able to record into a sound without any channels (brand-new sounds are like
  that).  Sounds only register the number of channels they have after they're done
  recording (a NeXTSTEP bug).  So if the Sound is recording, or for some other
  reason has a weird number of channels, this implementation of drawSelf will
  revert to Resound's default number of channels.

  A minor bug fix all told.
  
  ****************************************************************************/


#import "ResoundMiscVolumeMeter.h"

@implementation ResoundMiscVolumeMeter


/*** init
  Initializes the volume meter with a default
  channel count. 
*/

- init
    {
    id returnval=[ super init];
    default_channel_count=1;
    return returnval;
    }




/*** setDefaultChannelCount:
  sets the default channel count.
*/

- setDefaultChannelCount:(int) this
    {
    if (this==1||this==2) default_channel_count=this;
    return self;
    }




/*** drawSelf::
  Same as MiscVolumeMeter's drawSelf method, only this one makes some minor
  modifications to draw with the default number of channels if it can't be
  ascertained from the Sound/SoundView.
*/

- (void) drawRect:(NSRect) rects
{	NSRect drawRectLeft,drawRectRight;
    NSRect backgroundRect=[self bounds];
    NSRect valueRect=[self bounds];
    NSRect theBounds =[self bounds];
    float left,right;
    int just_erase=0;

    //if (![window isVisible]) return NULL;		// no window to draw in.
    // the above has been turned off because when loading Resound,
    // the sound meter wouldn't display until a sound was being played
    // or recorded!

    if ([delegate respondsToSelector:@selector(meterWillUpdate:)])
        [delegate meterWillUpdate:self];

    // first to check to see if the sound lock is current
    //printf ("Meter\n");
    if (sound!=NULL)
        {
        int status=NX_SoundStopped;
        id actual_sound=NULL;			// quiets compiler complaints

        if ([sound isKindOfClass:[Sound class]])
            {actual_sound=sound;}
        else if ([sound isKindOfClass:[SoundView class]])
            {actual_sound=[sound soundBeingProcessed];}
        status=[(Sound*)actual_sound status];	// TypeCast for OS X server
        if (status==NX_SoundStopped||
            status==NX_SoundInitialized||
            status==NX_SoundFreed)
        {just_erase=1;}

        // Then modify the meter to match the sound	

        else if (status==NX_SoundRecordingPaused||
                 status==NX_SoundRecording||
                 status==NX_SoundRecordingPending)
        {[self setToInput];}

        else if (status==NX_SoundPlayingPaused||
                 status==NX_SoundPlaying||
                 status==NX_SoundPlayingPending)
        {[self setToOutput];}

        /* Change for Resound */
        if ([actual_sound channelCount] <=0)
            /* unknown sound value, use the set default */
            {
            if (default_channel_count==2) [self setStereo];
            else [self setMono];
            }
        else

            /* End Change */

        if ([actual_sound channelCount]>1)
            {[self setStereo];}
        else {[self setMono];}
        }

    // then check for bezeled stuff


    if (bezeled)
        {
        backgroundRect.origin.x		+=VOLUMEMETER_BACKGROUND_INSET;
        backgroundRect.size.width	-=VOLUMEMETER_BACKGROUND_INSET*2;
        backgroundRect.origin.y		+=VOLUMEMETER_BACKGROUND_INSET;
        backgroundRect.size.height	-=VOLUMEMETER_BACKGROUND_INSET*2;

        valueRect.origin.x		+=VOLUMEMETER_VALUE_INSET;
        valueRect.size.width 		-=VOLUMEMETER_VALUE_INSET*2;
        valueRect.origin.y		+=VOLUMEMETER_VALUE_INSET;
        valueRect.size.height		-=VOLUMEMETER_VALUE_INSET*2;
        }
    else
        {
        valueRect.origin.x	+=
                VOLUMEMETER_VALUE_INSET-VOLUMEMETER_BACKGROUND_INSET;
        valueRect.size.width 	-=
                VOLUMEMETER_VALUE_INSET*2-VOLUMEMETER_BACKGROUND_INSET*2;
        valueRect.origin.y	+=
                VOLUMEMETER_VALUE_INSET-VOLUMEMETER_BACKGROUND_INSET;
        valueRect.size.height	-=
                VOLUMEMETER_VALUE_INSET*2-VOLUMEMETER_BACKGROUND_INSET*2;
        }

    if (!VOLUMEMETER_can_draw(&theBounds)) return;	// can't draw

    if (bezeled) NSDrawGrayBezel(theBounds , theBounds);
    PSsetgray(background_gray);
    NSRectFill(backgroundRect);

    if (just_erase) return;

    // compute for drawing

    if (running)
        {
        left=0;right=0;

        if (input&&input_device!=NULL)
            [input_device getPeakLeft:&left right:&right];

        if ((!input)&&output_device!=NULL)
            [output_device getPeakLeft:&left right:&right];

        if (left>1) left=1; if (right>1) right=1;
            // occasionally a NeXTSTEP bug returns values larger than 1!

        // perform refresh computations

        if (++refresh_tally>=refreshes_per_new_peak_bubble) refresh_tally=0;
        refreshes_left[refresh_tally]=left;
        refreshes_right[refresh_tally]=right;
        if (left>=refreshes_left[current_max_refresh_left])

    // remember, this might simply be because left stepped on the old champion!
    // ...search for new champion

            {
            int y;
            int maxpos=0;
            for (y=0;y<refreshes_per_new_peak_bubble;y++)
                if (refreshes_left[y]>refreshes_left[maxpos]) maxpos=y;
            current_max_refresh_left=maxpos;
            }
        if (right>=refreshes_right[current_max_refresh_right])
            // same as above!
            // ...search for new champion
            {
            int y;
            int maxpos=0;
            for (y=0;y<refreshes_per_new_peak_bubble;y++)
                if (refreshes_right[y]>refreshes_right[maxpos]) maxpos=y;
            current_max_refresh_right=maxpos;
            }

        // Draw away...

        if (VOLUMEMETER_draw_wide(&valueRect))		// draw wide
            {

            if (stereo)
                {

                // note that right and left are flipped,
                // so that when displaying wide, left is on the top.

                drawRectRight=valueRect;
                drawRectRight.size.height*=1-VOLUMEMETER_RIGHT_BEGIN;
                drawRectRight.origin.y+=valueRect.size.height*
                        VOLUMEMETER_RIGHT_BEGIN;
                drawRectRight.size.width*=left;

                drawRectLeft=valueRect;
                drawRectLeft.size.height*=VOLUMEMETER_LEFT_END;
                drawRectLeft.size.width*=right;
                }
            else
                {
                drawRectRight=valueRect;
                drawRectRight.size.width*=(right+left)/2.0;
                }
            }
        else										// draw tall
            {

            if (stereo)
                {
                drawRectRight=valueRect;
                drawRectRight.size.width*=1-VOLUMEMETER_RIGHT_BEGIN;
                drawRectRight.origin.x+=valueRect.size.width*
                        VOLUMEMETER_RIGHT_BEGIN;
                drawRectRight.size.height*=right;

                drawRectLeft=valueRect;
                drawRectLeft.size.width*=VOLUMEMETER_LEFT_END;
                drawRectLeft.size.height*=left;
                }
            else
                {
                drawRectRight=valueRect;
                drawRectRight.size.height*=(right+left)/2.0;
                }
            }
        if (left+right>0.0)			

        // I go through the computation because peak bubbles need it

            {
            PSsetgray(value_gray);
            NSRectFill(drawRectRight);
            if (stereo) NSRectFill(drawRectLeft);
            }
        // Draw Peak Bubbles			

        if (peak_bubble_displayed)
            {
            NSRect rightRect=drawRectRight;
            NSRect leftRect=drawRectLeft;
            float max_left=refreshes_left[current_max_refresh_left];
            float max_right=refreshes_right[current_max_refresh_right];

            if (max_left+max_right>0.0)
                {

                if (VOLUMEMETER_draw_wide(&valueRect))		// draw wide
                    {
                    rightRect.size.width=0.1;			// ...makes it a line
                    leftRect.size.width=0.1;

                    if (stereo)
                        {
                        rightRect.origin.x=floor(drawRectRight.origin.x+
                            valueRect.size.width*max_left);
                        leftRect.origin.x=floor(drawRectLeft.origin.x+
                            valueRect.size.width*max_right);
                        }
                    else
                        {
                        rightRect.origin.x=floor(drawRectRight.origin.x+
                            valueRect.size.width*
                            (max_right+max_left)/2.0);
                        }
                    }	
                else						// draw tall
                    {
                    rightRect.size.height=0.1;		// makes it a line
                    leftRect.size.height=0.1;

                    if (stereo)
                        {
                        rightRect.origin.y=floor(drawRectRight.origin.y+
                            valueRect.size.height*max_right);
                        leftRect.origin.y=floor(drawRectLeft.origin.y+
                            valueRect.size.height*max_left);
                        }
                    else
                        {
                        rightRect.origin.y=floor(drawRectRight.origin.y+
                            valueRect.size.height*
                            (max_right+max_left)/2.0);
                        }
                    }
                PSsetgray(bubble_gray);
                NSRectFill(rightRect);
                if (stereo) NSRectFill(leftRect);
                }
            }
        }
    PSWait();
    if ([delegate respondsToSelector:@selector(meterDidUpdate:)])
        [delegate meterDidUpdate:self];
}

@end
