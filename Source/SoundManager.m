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

  SoundManager.[h|m]
  Sean Luke
  
  SoundManager handles recording and playing sounds.  It works so closely with
  consoleManager that really the two should just be rolled into the same object.

  One important note:  SoundManager is the de facto delegate of all SoundViews and Sounds.
  So if you roll this one into the consoleManager etc., be sure to change
  all the delegate statements throughout the code (mostly here and in fileController).
  
  ****************************************************************************/



#import "SoundManager.h"
#import "FileController.h"
#import "ConsoleManager.h"
#import "ModuleController.h"

@implementation SoundManager


/*** init:
  initializes the Sound Manager
*/

- init
    {
    currentPlayingOrRecordingSoundView=nil;
    currentPlayingOrRecordingSound=nil;
    currentPlayingOrRecordingWindow=nil;
    playing=NO;
    recording=NO;
    paused=NO;
    return self;
    }



/*** Stop:
  Stops the currently-playing sound.
 */

- (void)stop:(id)sender;
    {
    if (playing)
	{
	[currentPlayingOrRecordingSoundView stop:self];
	[fileController setPlaying:currentPlayingOrRecordingWindow:NO];
	[[fileController getModuleController] soundDidPlay];
	}
    else if (recording)
	{
	[newSound stop:self];
	[[fileController getModuleController] soundDidRecord];
	}
    
    [consoleManager stopMeter];
    currentPlayingOrRecordingSoundView=nil;
    currentPlayingOrRecordingSound=nil;
    currentPlayingOrRecordingWindow=nil;
    playing=NO;
    recording=NO;
    paused=NO;
    //return self;
    }



/***
  Begins playing the current Sound and SoundView.
*/

- play:sender
    {
    currentPlayingOrRecordingSoundView=[fileController currentSoundView:self];
    currentPlayingOrRecordingSound=[fileController currentSound:self];
    currentPlayingOrRecordingWindow=[fileController currentWindow:self];
    if (!playing&&!recording)
	{
	if (currentPlayingOrRecordingSoundView!=nil&&currentPlayingOrRecordingSound!=nil)		// sound exists to play
	    {
	    if ([currentPlayingOrRecordingSound dataFormat]!=SND_FORMAT_UNSPECIFIED)		// a known sound
		{
		[currentPlayingOrRecordingSoundView play:self];
		[consoleManager setMeterTo:[currentPlayingOrRecordingSoundView soundBeingProcessed]];
		[consoleManager startMeter];
		[fileController setPlaying:currentPlayingOrRecordingWindow:YES];
		playing=YES;
		recording=NO;
		paused=NO;
		[[fileController getModuleController] soundNowPlaying];
		return self;
		}
	    }
	}
    // else	
    return nil;
    }





/*** TogglePaused:
  Pauses/unpauses a playing sound.
*/

- (int) togglePaused:sender
    {
    if (playing==YES)
	{
	if (paused==NO) {[currentPlayingOrRecordingSoundView pause:self]; paused=YES; return 1;}
	else {[currentPlayingOrRecordingSoundView resume:self]; paused=NO; return 2;}
	}
    else return 0;
    }




/*** Record:::::
  Records and returns a new sound with the given parameters.
*/

- record: (double) soundRate: (int) channels: (int) dataSize: (int) dataFormat: sender
    {
    if (!playing&&!recording)
	{
	newSound=[[Sound alloc] init];
	[newSound setDelegate:self];
	[newSound setDataSize: dataSize  
       dataFormat: dataFormat 
       samplingRate: soundRate 
       channelCount: channels 
       infoSize: 256];
	
	[newSound record:self];
	[consoleManager setDefaultChannelCount:channels]; // for ResoundMiscVolumeMeter 
	[consoleManager setMeterTo: newSound];
	[consoleManager startMeter];
	recording=YES;
	playing=NO;
	paused=NO;
	[[fileController getModuleController] soundNowRecording];
	return self;
	}
    return nil;
    }



/*** isPlaying
  Returns true if a sound is playing.
*/

- (BOOL) isPlaying
    {
    return playing;
    }


/*** isRecording
  Returns true if a sound is recording.
*/

- (BOOL) isRecording
    {
    return recording;
    }


/*** isPaused
  Returns true if a sound is paused while playing.
*/

- (BOOL) isPaused
    {
    return paused;
    }

/*** SoundPlayingOrRecording
  Returns the sound currently playing or recording.
*/

- soundPlayingOrRecording
    {
    return currentPlayingOrRecordingSound;
    }



/*** SoundViewPlayingOrRecording
  Returns the SoundView currently playing or recording.
*/

- soundViewPlayingOrRecording
    {
    return currentPlayingOrRecordingSoundView;
    }





// DELEGATE METHODS


/*** didPlay:
  Cleans up after a sound finished playing.  Informs the Console Manager, 
  Module Controller, etc.
*/

- didPlay:sender
    {
    // assumes sender is a soundview
    [sender setPlayMark:-1];
    [consoleManager stopDown:self];
    playing=NO;
    recording=NO;
    paused=NO;
    [[fileController getModuleController] soundDidPlay];
    return self;
    }

/*** didRecord:
  Cleans up after a sound finished recording.  Informs the Console Manager, 
  Module Controller, etc.  Hands the sound to the fileController to pop up on
  the screen.
*/

- didRecord:sender
    {
    playing=NO;
    recording=NO;
    paused=NO;
    [consoleManager stopDown:self];
    [fileController newRecordedSound: [newSound autorelease]];
    [[fileController getModuleController] soundDidRecord];
    return self;
    }




/*** selectionChanged:
  A delegate method that the ResoundMiscSoundView needs.  So when I receive it (I'm
  the delegate of all SoundViews), I bounce it back to a ResoundMiscSoundView method.
*/

- selectionChanged:sender			
    {
    return [sender updateStuff];
    }

/*** soundDidChange:
  FileConroller needs this one, so I forward it to the appropriate fileController
  method.  This assumes that the sender is the current sound!  Modules should not
  be fooling around with anything but the current sound and soundview.
*/

- soundDidChange:sender
    {
    return [fileController soundChanged: [fileController currentSound:self]];
    }

@end
