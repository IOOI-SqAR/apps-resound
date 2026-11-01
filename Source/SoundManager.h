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
#import <SoundKit/SoundKit.h>
#import <AppKit/NSWindow.h>
#import "ResoundMiscSoundView.h"

@interface SoundManager:NSObject
    {
    id  consoleManager;
    id  fileController;
    
    Sound*	currentPlayingOrRecordingSound;
    ResoundMiscSoundView*	currentPlayingOrRecordingSoundView;
    NSWindow*	currentPlayingOrRecordingWindow;
    Sound*   newSound;
    BOOL paused;
    BOOL playing;
    BOOL recording;
    }

- init;
- (void)stop:(id)sender;				// Stop playing.
- play:sender;		// Play the current sound.  Returns NULL if unable.
- record: (double) SoundRate: 
(int) channels: (int) DataSize: 
(int) dataFormat: sender;	      // Record a new sound.  Returns NULL if unable.

- (int) togglePaused:sender;	    // Turns Pause on or off.  Returns 1 if now paused,
                                    // 2 if now not paused, or 0 if cannot toggle.
- (BOOL) isPlaying;						// Sound is Playing
- (BOOL) isRecording;					// Sound is Recording
- (BOOL) isPaused;						// Sound is Paused
- soundPlayingOrRecording;  // Returns the sound playing or recording, NULL if none.
                                 // Note this is the sound, not the soundview's
                                 // scratch sound actually being used.
- soundViewPlayingOrRecording;

/*---IMPLEMENTED AS A DELEGATE OF SOUND AND SOUNDVIEW-----*/

- didPlay:sender;
- didRecord:sender;

@end
