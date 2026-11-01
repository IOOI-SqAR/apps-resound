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

@interface PreferencesManager:NSObject
    {
    id preferencesPanel;
    int preferencesPanelLoaded;
    
    id playOnOpenButton;
    id convertOnOpenButton;
    id backupButton;
        
    //  Attributes
    
    id minMaxDisplayButton;
    id oscilliscopicDisplayButton;
    id attributesMatrix;
    
    // Zoom
    
    id zoomedOutButton;
    id zoomedInButton;
    id zoomMatrix;

    // Marks
    
    id displayTicksButton;
    id displayAmplitudeButton;
    id displayZeroLineButton;
    id scrollToReflectSoundButton;
    
    id amplitudeButton;
    id minorTicksField;	
    id majorTicksField;
    id minorTicksFormatButton;
    }


- init;
- savePreferences;
- performPreferences;
- soundComingIn;

// a preferences look-up

- (BOOL) backup;
- (int) minMaxDisplay;
- (BOOL) zoomIn;
- (BOOL) displayTicks;
- (BOOL) scrollToReflectSound;
- (BOOL) displayZeroLine;
- (BOOL) displayAmplitude;
- (int) amplitudeFormat;
- (int) minorTickFormat;
- (float) minorTickValue;
- (int) majorTickValue;
- (BOOL) playOnOpen;
- (BOOL) convertOnOpen;

// for the preferences panel

- startPreferencesPanel:sender;
- preferencesOkayed:sender;

@end
