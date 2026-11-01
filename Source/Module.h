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

/***********************************************************************
 Module.h
 Sean Luke

 Module is the class that all Resound Modules subclass from.  It contains
 moduleController, a pointer to the gateway object for accessing Resound's
 API functions, and rootModuleMenuNode, the root-level node for creating
 the Module's submenu tree in Resound's "Modules" menu.
************************************************************************/


#import <Foundation/Foundation.h>
#import "ModuleProtocol.h"
#import "ModuleMenuNode.h"
#import "ModuleSound.h"

/* For backwards compatibility with 2.5 source */
#define TheModuleController moduleController
#define TheModuleMenuNode rootModuleMenuNode


@interface Module:NSObject
{
	id			<ModuleProtocol> moduleController;
	id 			rootModuleMenuNode;
}

- (void) dealloc;			// frees module, TheModuleMenuNode, and submenu nodes
- init;			// generates TheModuleMenuNode.

- setModuleControllerTo: thisModuleController;	/* Private method.  Don't fool with it */	
- getModuleMenuNode;	// returns the ModuleMenuNode. Used privately.
   
- soundDidChange;		// informs the Module that the current sound may have 
						// changed.
- nowPlaying;
- nowRecording;
- didPlay;
- didRecord;
  
@end
