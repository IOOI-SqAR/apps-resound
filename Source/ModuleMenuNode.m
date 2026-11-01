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

  ModuleMenuNode.[h|m]
  Sean Luke
  
  The ModuleMenuNode object is a tree which defines the menu structure for a
  module.  It's *very* straightforward.
  
  ****************************************************************************/




#import "ModuleMenuNode.h"
#import <string.h>

@implementation ModuleMenuNode

- initLeafNode:(NSString*) this_name:(NSObject*) this_receiver:(SEL)this_message
{
    id returnval=[super init];
    receiver=[this_receiver retain];
    name=[this_name copy];
    message=this_message;
    submenu=[[NSMutableArray alloc] initWithCapacity:0];
    leaf_node=YES;
    return returnval;
}

- initNonleafNode:(NSString*)this_name
{
    id returnval=[super init];
    name=[this_name copy];
    submenu=[[NSMutableArray alloc] initWithCapacity:0];
    leaf_node=NO;
    return returnval;
}

- (BOOL) isLeafNode { return leaf_node; }

- (void) dealloc
    {
    [name release];
    [submenu release];
    [super dealloc];
    }

- (NSString*) getNameAsString
{
    return name;
}

- setNameToString: (NSString*) this_name
{
    [name release];
    name=[this_name copy];
    return self;
}


- getReceiver
    {
    return receiver;
    }


- setReceiver: this_receiver
    {
    leaf_node=YES;  // for backward-compatibility
    receiver=this_receiver;
    return self;
    }


- (SEL) getMessage
    {
    return message;
    }


- setMessage: (SEL) this_message
    {
    leaf_node=YES;  // for backward-compatibility
    message=this_message;
    return self;
    }

- getSubmenu: (int) this_index
    {
    return [submenu objectAtIndex:this_index];
    }

- (int) numSubmenus
    {
    return [submenu count];
    }

- addSubmenu:(ModuleMenuNode*) this_node
{
    [submenu addObject:this_node];
    return self;
}





/*  ----- IMPLEMENTED AS BACKWARD-COMPATIBILITY ONLY ----- */



- setLength:(int) this_length
    {
    /* This is now completely ignored */
    length=this_length;
    return self;
    }



- (int) getLength
    {
    return length;
    }


- setSubmenu: (int) this_index : this_node
/* Note this may break some people's old Resound 2.5 code if they don't insert
   in ordinary ascending order! This is because of the nature
   of NSArray.  Sorry.  */
    {
    if (this_index<length&&this_index>=0)
	{
    return [self addSubmenu:this_node];
	}
    else return nil;
    }


- setName: (char *) this_name
    {
    [self setNameToString:[NSString stringWithCString:this_name]];
    return self;
    }

- (const char*) getName
    {
    return (const char*) [[self getNameAsString] lossyCString];
    }



- init
    {
    id returnval=[super init];
    name=@"";
    receiver=nil;
    submenu=[[NSMutableArray alloc] initWithCapacity:0];
    return returnval;
    }




@end	
