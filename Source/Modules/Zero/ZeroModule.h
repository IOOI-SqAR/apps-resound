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

/*
ZeroModule
For Resound 3.0
Sean Luke

A simple example module which zeroes out the selected sound, to get you
started using Resound modules.  This code is discussed in Resound's Help
facility, under the section "Building a Resound Module: A Walk-Though".
*/


	#import "Module.h"

	@interface ZeroModule:Module
	{
	}

	- init;
	- zeroSound:sender;

	@end
