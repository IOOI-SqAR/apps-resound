/*
Copyright (c) 1998 by Sean Luke

Permission to use, copy, modify, and distribute this material 
for any purpose is granted only with the sole permission of Sean Luke,
and provided that this permission notice 
appear in all source copies, and that the author's name shall not
be used in advertising or publicity pertaining to this 
material without the specific, prior written permission 
of the author.  SEAN O. LUKE  MAKES NO REPRESENTATIONS ABOUT THE
ACCURACY OR SUITABILITY OF THIS MATERIAL FOR ANY PURPOSE.  
IT IS PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.

*/


#import <Foundation/Foundation.h>
#import "ModuleProtocol.h"
#import <objc/List.h>

@interface ModuleController:NSObject <ModuleProtocol>
    {
    id fileController;
    id infoManager;
    id soundManager;
    id zoomController;
    id selectionManager;
    id compactPanel;
    id adjustButton;
    id loadPanel;
    id fileName;
    id pathName;
    NSMutableArray* modules;
    NSMutableArray* helpnames;
    NSMutableArray* helpfiles;
    int numhelp;
    
    id moduleHelpView;
    id moduleHelpWindow;
    
    BOOL goAhead;		     //  The Compact Panel has been okayed.
    
    int loaded;
    int windowsLoaded;
    }


/*---------Private methods. On pain of death, do not call these methods-they are internal---------*/

- init;
- (void) dealloc;
- loadModules;
- (void) loadAModule: (NSString *)file;
- generateHelpMenu:(NSString*) helpResourcePath:(NSString*)moduleName:this_menu;
- generateMenu:this_node:this_menu;		// do not call this.  Used by LoadModules
- turnOffMenu:sender;
- turnOnMenu:sender;
- update;
- soundDidRecord;
- soundDidPlay;
- soundNowPlaying;
- soundNowRecording;






/*---------------------METHODS PROPERLY CALLABLE BY MODULES----------------------*/

// See ModuleProtocol.h for comments on these methods.

- (BOOL) runCompactPanel;
- (BOOL) runLongTimePanel;
- run16BitOnlyPanel;
- runNoSoundPanel;

- currentSound;
- currentSoundView;
- currentWindow;
- currentPlayingSound;
- currentPlayingSoundView;
- currentPlayingWindow;	

- brandNewSound: thisSound;
- newSound: thisSound for: thisSoundView;

- soundChanged;
- soundTouched;
- selectionChanged;
- infoChanged;
- zoomChanged;

- stop;	
- (BOOL) isPlaying;
- (BOOL) isRecording;

- moduleWindowDidBecomeMain;
@end
