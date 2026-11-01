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

  Module.[h|m]
  Sean Luke
  
  Module is the superclass of all modules.  It has a few private methods for
  setting up the module and loading it into Resound, but mostly it's an abstract
  superclass of module-access methods for the Resound API.
  
  ****************************************************************************/




#import "ModuleController.h"
#import "Module.h"
#import <stdio.h>

@implementation Module


/*** init
  Initializes the module.
  */

- init
    {
    id returnval=[super init];
    rootModuleMenuNode=[[ModuleMenuNode alloc] initNonleafNode:@""];
    return returnval;
    }


/*** dealloc
  Frees the module.  Note that the ModuleMenuNode is freed (which frees all its
  subordinate menu nodes)
  */

- (void) dealloc
    {
    if (moduleController!=nil) [(ModuleController*)moduleController release];
    [rootModuleMenuNode release];
    [super dealloc];
    }



/*** setModuleControllerTo:
  Sets up the ModuleController once the Module is loaded, with some double-checking.
  An effectively private method.
  */

- setModuleControllerTo: thisModuleController
    {
    if (moduleController!=nil) [(ModuleController*)moduleController release];
    moduleController=[thisModuleController retain];
    
    if (moduleController==nil)
	{
	printf ("Module.m ERROR\n\t In method setModuleControllerTo:"
		"andTheNXBundleTo:\n\tmoduleController is nil.\n");
	return nil;
	}
    if (![(ModuleController*)moduleController
        conformsToProtocol:@protocol(ModuleProtocol)])
	{
	printf ("Module.m ERROR\n\t In method setModuleControllerTo:"
		"andTheNXBundleTo:\n\tmoduleController does not "
		"conform to the ModuleProtocol protocol.\n");
	return nil;
	}
    
    return self;
    }


/*** getModuleMenuNode
  Returns the ModuleMenuNode, with some double-checking.  An effectively private method.
  */

- getModuleMenuNode
    {
    if (rootModuleMenuNode==nil) 
	{
	printf ("Module.m ERROR\n\tIn method getModuleMenuNode "
		"\n\trootModuleMenuNode is nil.\n");
	}
    else if ([ModuleMenuNode class]!=[rootModuleMenuNode class])
	{
	printf ("Module.m ERROR\n\tIn method getModuleMenuNode "
		"\n\trootModuleMenuNode is not a ModuleMenuNode instance.\n");
	}
    return rootModuleMenuNode;
    }

/*** soundDidChange
  Abstract method.  
  Called when a sound has changed and the module might need to update itself.
  */

- soundDidChange
    {
    return self;
    }

/*** nowPlaying
  Abstract method.  
  Called when a sound has begun playing.
  */

- nowPlaying
    {
    return self;
    }


/*** nowRecording
  Abstract method.  
  Called when a sound has begun recording.
  */

- nowRecording
    {
    return self;
    }



/*** didPlay
  Abstract method.  
  Called when a sound has finished playing.
  */


- didPlay
    {
    return self;
    }


/*** didRecord
  Abstract method.  
  Called when a sound has finished recording.
  */


- didRecord
    {
    return self;
    }




@end
