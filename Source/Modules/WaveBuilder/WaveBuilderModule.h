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


#import "Module.h"


@interface WaveBuilderModule:Module
{
    id	sinAmplitudes;
    id	sinPhases;
    id	sinHarmonics;
    id	percentDoneSin;
    id	othersAmplitude;
    id	percentDoneOthers;
    id	othersLength;
    id	sinLength;
    id	othersSize;
	id sinTextAmplitudes;
	id sinTextPhases;
	id sinTextHarmonics;
id sinPopUpButton;

	id  sinPanel;
	id  othersPanel;
    
	int  whichToDo;
	int  windowLoaded;
}

- init;
- generateSin:sender;
- generateOthers:sender;
- loadSinPanel:sender;
- loadOthersPanel:sender;

// conversions

- A:sender;
- As:sender;
- B:sender;
- C:sender;
- Cs:sender;
- D:sender;
- Ds:sender;
- E:sender;
- F:sender;
- Fs:sender;
- G:sender;
- Gs:sender;
- cosA:sender;
- clear:sender;
- doNoise:sender;
- doSquare:sender;
- doPulse:sender;
- doTriangle:sender;
- doSawtooth:sender;

@end
