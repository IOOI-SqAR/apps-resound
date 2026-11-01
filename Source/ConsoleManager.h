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

#define __BUILDING_RHAPSODY


#import <Foundation/Foundation.h>
#import <SoundKit/SoundKit.h>

@interface ConsoleManager:NSObject
    {
    id	fileController;			// program objects.
    id  soundManager;
    
    id  console;		
    id	meter;
#ifndef __BUILDING_RHAPSODY
    id  light;
#endif

    id	stopButton;				// interface objects.
    id	playButton;
    id 	pauseButton;
    id	recordButton;
    
    id	soundTracker;
    id	rateMenu;
    id	rateField;
    id	formatMenu;
    id	source;
    id	channels;
    id 	formatWindow;
    id	leftRecordGain;
    id	rightRecordGain;
    id	monoRecordGain;
    id	minrate;
    id	maxrate;
    id	recordLengthField;
    id  hidden_window;                   // for the app icon
    
    NXSoundIn* sound_device;
    }

- init;
- (void) dealloc;
- prepareConsole;		// sets up console initially
- showConsole:sender;

- stopDown:sender;
- pauseDown:sender;
- playDown:sender;
- recordDown:sender;

- setMeterTo:thisSound;
- stopMeter;
- startMeter;

- setRight:sender;
- setLeft:sender;
- setMono:sender;
- setRateToMe:sender;
- setFormatToMe:sender;
- displayRecordFormatPanel:sender;

- setMonoChannels:sender;
- setStereoChannels:sender;
- setSourceMic:sender;
- setSourceLine:sender;
- setRecordingLength:sender;

- setDefaultChannelCount:(int) chan;

// Implemented as a delegate of VolumeMeter

- meterWillUpdateOnOwn:sender;			// tack off of this to do auto-updates
- clearPlayMark;



@end
