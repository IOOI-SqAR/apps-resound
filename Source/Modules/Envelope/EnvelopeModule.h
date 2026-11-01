/*
	EnvelopeModule.h
	A simple sound enveloping module for Resound
	1.0, 1995-01-29, andrew abernathy
*/


#import "Module.h"


@interface	EnvelopeModule : Module
{
	id	envelopePanel;		// the enveloping control panel
	id	applyButton;		// apply envelope button
	id	inOutMatrix;		// fade-in/fade-out radio button matrix
	id	applyToLeftButton;	// left channel checkbox
	id	applyToRightButton;	// right channel checkbox
	id	applyToAllButton;	// all channels checkbox
}

- init;					// initialize

- soundDidChange;			// update self - sound has changed
- showEnvelopePanel:sender;		// display our control panel
- applyEnvelope:sender;			// apply the envelope to the sound

@end	// EnvelopeModule
