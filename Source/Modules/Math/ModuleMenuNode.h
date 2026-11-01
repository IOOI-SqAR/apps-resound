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
 ModuleMenuNode.h
 Sean Luke

 ModuleMenuNode is used by modules to build their menus when they're
 loaded into Resound.  See the ModuleMenuNode.rtfd or ModuleMenuNode.htmld
 documentation for information on how to use this object.   See Resound's 
 Help system for more information.
************************************************************************/




#import <Foundation/Foundation.h>
/* they don't do anything now, but for backward compatilibility reasons we include them here */
#define MODULE_MENU_NODE_ARRAY_MAX  256  
#define MODULE_MENU_NODE_STRING_MAX 256

@interface ModuleMenuNode:NSObject


/* DATA */

{
	// items that are leaf nodes are defined with this boolean
	BOOL leaf_node;

	// all menu items have a name.
	NSString* name;

	// leaf node items have receivers, and messages.
	id   receiver;  // Receiver of method
	SEL  message;   // Selector to be sent
	
	// all menu items have a submenu array, but for leaf
	// nodes the size of the array is 0.
        NSMutableArray* submenu;	// The Submenu Array	

	// this is for backward compatibility only.	
	int  length;	// Length of Array.  Now unused in new API.
}



/*  METHODS */

- initLeafNode:(NSString*) this_name:(NSObject*) this_receiver:(SEL)this_message;
- initNonleafNode:(NSString*)this_name;
- (void)dealloc;

// get various data

- (NSString*) getNameAsString;
- getReceiver;
- (SEL) getMessage;
- getSubmenu: (int) this_index;
- (int) numSubmenus;
- (BOOL) isLeafNode;

// set various data

- setNameToString: (NSString*) this_name;
- setReceiver: this_receiver;
- setMessage: (SEL) this_message;
- addSubmenu:(ModuleMenuNode*) this_node;  /* added in order from top to bottom */


// Backward Compatibility only

- init;  /* Backward-compatibility */
- (int) getLength;
- setLength:(int) this_length;
- setName: (char *) this_name;  /* Backward-compatibility */
- (const char*) getName;  /* Backward-compability */
- setSubmenu: (int) this_index : this_node;  /* Backward-compatibility */

@end
