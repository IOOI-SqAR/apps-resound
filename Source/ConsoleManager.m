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

  ConsoleManager.[h|m]
  Sean Luke
  
  The Console Manager is the controller object responsible for handling the
  Console Window, the Record and Play panels, and the auto-scroll and play mark
  on Resound's SoundViews.  The ConsoleManager works closely with the SoundController,
  which is the object responsible for actually managing recording and playing of
  sounds.  Realistically, these two objects could be merged at a later date, but
  intertia prevents me from doing so.  :-)
  
  ****************************************************************************/





#import "ConsoleManager.h"
#import "FileController.h"
#import "SoundManager.h"
#import "ResoundMiscVolumeMeter.h"
#import "MiscSoundTracker.h"
#import "ResoundMiscSoundView.h"
#import <AppKit/AppKit.h>
#import <SoundKit/SoundKit.h>
#import <stdio.h>

#ifndef __BUILDING_RHAPSODY
#import "MiscVolumeLight.h"
//#import "MiscAppIcon.h"
#endif

#define SOURCE_MIC @"Mic"
#define SOURCE_LINE @"Line"
#define LENGTH_5_MINUTES @"300"        /* String Macro Value -- can't have ints in strings */
#define F_LENGTH_5_MINUTES 300.0      /* Integer Macro Value */

@implementation ConsoleManager


/**** registerDefaults:::::
  Initializes defaults for console manager.
*/


- registerDefaults
{
    NSString* channel;
    NSString* rate;
    NSString* encoding;

    NSDictionary* dict;
    /*float *s_rates;
    unsigned int n_rates;*/
    NXSoundParameterTag *encodings;
    unsigned int n_encodings;

    if ([sound_device streamChannelCountLimit]>0)
        channel = (([sound_device streamChannelCountLimit]==1) ? @"1" : @"2");
    else channel = @"-1";

	{
	double defaultrate = 22050;
	double lowrate= 500;
	double hirate = 1000000;
	double r = [[[[Sound alloc] init] autorelease] samplingRate];
	rate = [NSString stringWithFormat:@"%f", (r > lowrate && r < hirate ?
		r : defaultrate)];
	}

    /*
	if ([sound_device acceptsContinuousStreamSamplingRates])
        {
        float lowrate=22050;
        float hirate=44100;
        [sound_device getStreamSamplingRatesLow:&lowrate high:&hirate];
        rate = [NSString stringWithFormat:@"%f",hirate];
        }
    else
        {
        [sound_device getStreamSamplingRates:&s_rates count:&n_rates];
        if (n_rates)  rate = [NSString stringWithFormat:@"%f",s_rates[n_rates-1]];
        else rate = @"-1";	// default...
        }
	*/

    [sound_device getStreamDataEncodings:&encodings count:&n_encodings];
    if (n_encodings) encoding=@"0";
    else encoding=@"-1";	// default...

    dict=
        [NSDictionary dictionaryWithObjectsAndKeys:
            channel, @"RecordChannels",
            rate, @"RecordRate",
            encoding, @"RecordEncoding",
            SOURCE_MIC, @"RecordSource",
            LENGTH_5_MINUTES, @"RecordLength",
            nil];

    [[NSUserDefaults standardUserDefaults] registerDefaults:
        dict];
    return self;
    }







/**** init
  Initializes Console Manager 
*/

- init
    {
    id returnval=[super init];
    float *s_rates;
    unsigned int n_rates;
    NXSoundParameterTag *encodings;
    unsigned int n_encodings;
    int x;

    NSString* defaultChannel;
    NSString* defaultRate;
    NSString* defaultEncoding;
    NSString* defaultSource;
    NSString* defaultLength;
    
    sound_device = [[NXSoundIn alloc] init];
    [NSBundle loadNibNamed: @"Console.nib" owner:self];
    
    // Register Defaults
    
    [self registerDefaults];

    {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        defaultChannel = [defaults stringForKey: @"RecordChannels"];
        defaultRate = [defaults stringForKey: @"RecordRate"];
        defaultEncoding = [defaults stringForKey: @"RecordEncoding"];
        defaultSource = [defaults stringForKey: @"RecordSource"];
        defaultLength = [defaults stringForKey: @"RecordLength"];
    }

    
#ifndef __BUILDING_RHAPSODY
    // Set up hidden window
    
	{
	NSPoint	contentViewOrigin = { 8.0, 8.0 };
	[NSApp cleanTileToWindow: hidden_window];
	[[hidden_window contentView] lockFocus];
	[[NXImage findImageNamed: @"FourSounds"] composite:NX_SOVER toPoint:&contentViewOrigin];
	[[hidden_window contentView] unlockFocus];
	}
#endif

    // start trackers
    
    [soundTracker setRefresh:.05];
    [soundTracker sendSeconds];
    [soundTracker setDefaultSamplingRate:SND_RATE_CODEC];
    [meter setDelegate:self];
    [meter setRefresh:.05];
#ifndef __BUILDING_RHAPSODY
    [Light setDelegate:self];
    [Light setBezeled:NO];
    [Light setRefresh:.05];
#endif
    
    // Set the Input Gains...
    
    [monoRecordGain setFloatValue: [sound_device floatValueForParameter:
				    NX_SoundDeviceInputGainStereo]];
    [leftRecordGain setFloatValue: [sound_device floatValueForParameter:
				    NX_SoundDeviceInputGainLeft]];
    [rightRecordGain setFloatValue:[sound_device floatValueForParameter:
				    NX_SoundDeviceInputGainRight]];	

    // Set the Input Source...

    if ([defaultSource isEqualToString:SOURCE_LINE])
	{
	id nxsi=[[NXSoundIn alloc] init];
	[nxsi setParameter:NX_SoundDeviceAnalogInputSource toInt: 		
	 NX_SoundDeviceAnalogInputSource_LineIn];
	[nxsi release];
	}
    else 
	{
	id nxsi=[[NXSoundIn alloc] init];
	[nxsi setParameter:NX_SoundDeviceAnalogInputSource toInt: 		
	 NX_SoundDeviceAnalogInputSource_Microphone];
	[nxsi release];
	}
    

    // Here we figure out what rates and formats are available...
    
    [recordLengthField setStringValue:defaultLength];
    
    if ([sound_device streamChannelCountLimit]==1)
	// Warning, bug in NeXT's docs the name is totally wrong...
	{
	[[channels cellAtRow:1 column:0] setEnabled:NO];
    defaultChannel=@"1";
	}
    else
	{		// which to set?
	int c=[defaultChannel intValue];
	switch (c)
	    {
	  case 2:  defaultChannel=@"2"; break;
      default: defaultChannel=@"1"; break;
		   }		// maybe more later...
	}

    // Set the available rates...

    if ([sound_device acceptsContinuousStreamSamplingRates])
	{
        NSString* t;
	float lowrate=22050;
	float hirate=44100;
	[rateMenu setEnabled:NO];
	[rateField setEnabled:YES];
	[rateMenu addItemWithTitle: @"User-Defined:"];
    [rateMenu selectItemWithTitle: @"User-Defined:"];
	[sound_device getStreamSamplingRatesLow:&lowrate high:&hirate];
	// Work-around for a little sprintf bug...
	if (lowrate==floor(lowrate))	// it's a round number
	    t=[NSString stringWithFormat:@"%d",(int)floor(lowrate)];
	else
        t=[NSString stringWithFormat:@"%f",lowrate];
	[minrate setStringValue:t];
	if (hirate==floor(lowrate))	// it's a round number
        t=[NSString stringWithFormat:@"%d",(int)floor(hirate)];
	else
        t=[NSString stringWithFormat:@"%f",hirate];
	[maxrate setStringValue:t];
	if ([defaultRate floatValue]<=hirate&&[defaultRate floatValue]>=lowrate)
        [rateField setFloatValue:[defaultRate floatValue]];
	else
	    {
	    [rateField setFloatValue:hirate];
	    defaultRate=[NSString stringWithFormat:@"%f",hirate];
        }
	}
    else
	{
	[sound_device getStreamSamplingRates:&s_rates count:&n_rates];
	if (n_rates)
	    {
	    int s=0;				// no format set...
        NSString* t;
	    [rateMenu setEnabled:YES];
	    [rateField setEnabled:NO];
	    for (x=0;x<n_rates;x++)
		{
		// Work-around for a little sprintf bug...
		if (s_rates[x]==floor(s_rates[x]))	// it's a round number
		    t=[NSString stringWithFormat:@"%d",(int)floor(s_rates[x])];
		else
		    t=[NSString stringWithFormat:@"%f",s_rates[x]];

        [[[rateMenu menu] addItemWithTitle:t
            action:@selector(setRateToMe:)
            keyEquivalent:@""] setTarget:self];
        if (x==0) [rateMenu selectItemWithTitle:t];
        if ([t intValue]==[defaultRate intValue]) {[rateMenu selectItemWithTitle:t]; s=1;}
		}
	    if (!s) defaultRate=[NSString stringWithFormat:@"%s",[rateMenu title]];
        [[rateMenu menu] removeItem: [[rateMenu menu] itemWithTitle:@"Default"]];
	    }
	else
	    {
	    defaultRate=@"-1";
	    [rateMenu setEnabled:NO];
	    [rateField setEnabled:NO];
	    }
	}

    // set the available encodings...
    
    [sound_device getStreamDataEncodings:&encodings count:&n_encodings];
    
    if (n_encodings)
	{
	int s=0;			// unset
	int sx=0;
	int usable=1;		// some encodings aren't usable
    NSString* t;
	[formatMenu setEnabled:YES];
	for (x=0;x<n_encodings;x++)
	    {
	    switch (encodings[x])
		{
	      case NX_SoundStreamDataEncoding_Linear16:
              t=@"16-Bit Linear"; usable=1;break;
	      case NX_SoundStreamDataEncoding_Linear8:
              t=@"8-Bit Linear";  usable=1;break;
	      case NX_SoundStreamDataEncoding_Mulaw8:
              t=@"8-Bit Mu-Law"; usable=1;break;
	      case NX_SoundStreamDataEncoding_Alaw8:
              t=@"8-Bit A-Law";  usable=0;break;
	      case NX_SoundStreamDataEncoding_AES:
              t=@"AES";  usable=0;break;
	      default:
              t=@"Unknown"; usable=0;break;
		}
        [[[formatMenu menu] addItemWithTitle:t
                        action:@selector(setFormatToMe:)
                 keyEquivalent:@""] setTarget:self];
        if (x==0) [formatMenu selectItemWithTitle:t];
        if (x==[defaultEncoding intValue])
        {
            [formatMenu selectItemWithTitle:t];
        s=1; sx=x;
        }
    }
	if (!s) defaultEncoding=[NSString stringWithFormat:@"%d",sx];
    [[formatMenu menu] removeItem:[[formatMenu menu] itemWithTitle: @"Default"]];
	}
    else
	{
	defaultEncoding=@"-1";
	[formatMenu setEnabled:NO];
	}

    {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: defaultChannel forKey: @"RecordChannels"];
    [defaults setObject: defaultRate forKey: @"RecordRate"];
    [defaults setObject: defaultEncoding forKey: @"RecordEncoding"];
    [defaults setObject: defaultSource forKey: @"RecordSource"];
    [defaults setObject: defaultLength forKey: @"RecordLength"];
    }
    return returnval;
    }




/**** setDefaultChannelCount:
  Sets the Volume Meter's default channel count.
*/


- setDefaultChannelCount:(int) chan
    {
    return [meter setDefaultChannelCount:chan];
    }


/**** dealloc
  Frees the Console Manager and cleans up.
 */

- (void)dealloc
    {
    [(MiscSoundTracker*)soundTracker stop];
    [sound_device release];
    [super dealloc];
    }



/**** PrepareConsole
  Set up the console at program-initialization time.  Called from FileController.
  */

- prepareConsole
    {
    [console makeKeyAndOrderFront:self];
    return self;
    }


/**** ShowConsole:
  Display the console.  Called by a menu item.
 */

- showConsole:sender;
    {
    [console makeKeyAndOrderFront:sender];
    return self;
    }


/**** SetMeterTo:
  Lock the meter, volume light, and trackers onto a particular sound/soundview for
  recording or playing.  This method does not start them running--see StartMeter.
 */

- setMeterTo: thisSound
    {
    [(SoundMeter*)meter setSound: thisSound];	// TypeCast for OS X server	
#ifndef __BUILDING_RHAPSODY
    [light setSound: thisSound];
#endif
    [(SoundMeter*)soundTracker setSound:thisSound];	// TypeCast for OS X server
    return self;
    }


/**** StopMeter
  Stop the meter, volume light, and trackers.  Unlock them from any sound/soundview.
  */

- stopMeter
    {
    [(ResoundMiscVolumeMeter*)meter stop];
#ifndef __BUILDING_RHAPSODY
    [(MiscVolumeLight*)light stop];
#endif
    // First a little spoofing to make certain that play mark is removed...
    [self clearPlayMark];
    [(SoundMeter*)meter setSound:nil];	// so VolumeMeter isn't using sound	// TypeCast for OS X server
    // in case sound is freed later
#ifndef __BUILDING_RHAPSODY
    [light setSound:nil];
#endif
    [(MiscSoundTracker*)soundTracker stop];
    [soundTracker clearTarget];
    return self;
    }



/**** StartMeter
  Start the meter, volume light, and trackers running.
*/

- startMeter
    {
    [meter run];
#ifndef __BUILDING_RHAPSODY
    [light run];
#endif
    [soundTracker run];	
    return self;
    }




/*** PlayDown:
  Do what's needed to do when the Play Button has been pressed.
*/

- playDown:sender
    {
    if ([fileController currentSound:self]!=nil)
	{	
	if ([(SoundManager*)soundManager play:self]!=nil) return self;	
	}
    
    // else...
    [playButton setState:(![playButton state])];
    return self;
    }




/**** RecordDown:
  Do what's needed to do when the Record Button has been pressed.
  */

- recordDown:sender
    {

    NXSoundParameterTag *encodings;
    unsigned int n_encodings;
    float *s_rates;
    int n_rates;
    int x;

    NSString* defaultChannel;
    NSString* defaultRate;
    NSString* defaultEncoding;
    NSString* defaultSource;
    NSString* defaultLength;
    int c,e;
    float r,l;

    {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        defaultChannel = [defaults stringForKey: @"RecordChannels"];
        defaultRate = [defaults stringForKey: @"RecordRate"];
        defaultEncoding = [defaults stringForKey: @"RecordEncoding"];
        defaultSource = [defaults stringForKey: @"RecordSource"];
        defaultLength = [defaults stringForKey: @"RecordLength"];
    }
    
    [sound_device getStreamDataEncodings:&encodings count:&n_encodings];

    c=[defaultChannel intValue]; if (c<=0) c=1; if (c>2) c=2;
    r=[defaultRate intValue]; if (r<=0) r=1;

    if ([sound_device acceptsContinuousStreamSamplingRates])
	{
	float lowrate, hirate;
	[sound_device getStreamSamplingRatesLow:&lowrate high:&hirate];
	if (r<=lowrate||r>=hirate) r=hirate;
	}
    else
	{
	[sound_device getStreamSamplingRates:&s_rates count:&n_rates];
	for (x=0;x<n_rates&&r!=s_rates[x];x++);
	r=s_rates[x];
	if (!n_rates) r=SND_RATE_CODEC;
	}
    
    e=[defaultEncoding intValue];
    if (e>=0&&e<n_encodings) e=encodings[e];
    else e=NX_SoundStreamDataEncoding_Mulaw8;
    
    if ([defaultSource isEqualToString:SOURCE_LINE])
	{
	NXSoundIn* nxsi=[[NXSoundIn alloc] init];
	[nxsi setParameter:NX_SoundDeviceAnalogInputSource toInt: 		
	 NX_SoundDeviceAnalogInputSource_LineIn];
    [nxsi dealloc];}
    else 
	{
	NXSoundIn* nxsi=[[NXSoundIn alloc] init];
	[nxsi setParameter:NX_SoundDeviceAnalogInputSource toInt: 		
	 NX_SoundDeviceAnalogInputSource_Microphone];
	[nxsi dealloc];}
    
    l=[defaultLength intValue];
    if (l<=0.0) l=F_LENGTH_5_MINUTES;
    
    // Now, we convert the weird parameters into 

    switch (e)
	{
      case NX_SoundStreamDataEncoding_Linear16: e=SND_FORMAT_LINEAR_16; break;
      case NX_SoundStreamDataEncoding_Linear8: e=SND_FORMAT_LINEAR_8; break;
      case NX_SoundStreamDataEncoding_Mulaw8: e=SND_FORMAT_MULAW_8; break;
      default: e=SND_FORMAT_MULAW_8; break;
	}

    [soundTracker setDefaultSamplingRate:r];
    
    if ([soundManager record: r: c:  (int) ((e==SND_FORMAT_LINEAR_16 ? 2 : 1)*r*l*c):  e : self] )
    	{
    	[recordButton setState:1];
	//return self;
    	}
    // else
    else
    	[recordButton setState:0];
    //[recordButton setState:(![recordButton state])];
    return self;
    }




/**** PauseDown:
  Do what's needed to do when the pause button has been pressed.
  This could be improved by storing the current number of samples played, as the Sound
  mechanism doesn't keep track of this and therefore the play mark gets reset every time
  you press pause and then unpause again.  Bummer.
*/

- pauseDown:sender
    {	
    if (![soundManager togglePaused:self])
	{
	[pauseButton setState:(![pauseButton state])];
	}
    return self;
    }




/**** StopDown:
  Do what's needed to do when the stop button has been pressed.  Basically, reset stuff.
 */

- stopDown:sender
    {
    [(SoundManager*)soundManager stop:self];
    [recordButton setState:0];
    [playButton setState:0];
    [stopButton setState:0];
    [pauseButton setState:0];
    return self;
    }



/**** meterDidUpdate:
  Delegate method.  If the sender is the VolumeLight in the app icon, then we need to
  set up the icon correctly.  Otherwise we don't do anything.
*/

- meterDidUpdate:sender
    {
#ifndef __BUILDING_RHAPSODY    if (sender==Light)
	{
	return [NSApp windowToAppIcon:hidden_window];	
	// A MiscAppIcon category method
	}
    else 
#endif
        return self;
    }




/**** metterWillUpdateOnOwn:sender
  Delegate method.  If the sender is the VolumeLight, we need to load it into the app icon.
  otherwise, we need to do the auto-scrolling and play mark functions in the SoundView, which
  are tied to the Meter.
*/

- meterWillUpdateOnOwn:sender
    {
#ifndef __BUILDING_RHAPSODY
    if (sender==Light)
	{
	NSPoint	contentViewOrigin = { 8.0, 8.0 };
	[NSApp cleanTileToWindow: hidden_window];
	[[hidden_window contentView] lockFocus];
	[[NXImage findImageNamed: @"FourSounds"] composite:NX_SOVER toPoint:&contentViewOrigin];
	[[hidden_window contentView] unlockFocus];
	return self;
	}
    else
	{
#endif

    	id snd=[(SoundMeter*)sender sound];		// note that the meter is tracking the scratch sound,	// TypeCast for OS X server
	// not the real sound!
	id cv=[soundManager soundViewPlayingOrRecording];
	int st;
	int samp;
	int fs,ns;
	BOOL ruler_drawn;
	BOOL need_to_scroll;
	
	if (snd==nil) return self;
	if (cv==nil) return self;

	// First we check to see if the SoundView's even bothering with
	// displaying the ruler or scroll...
	
	ruler_drawn=[cv xAxisDisplayed];
	need_to_scroll=[cv scrollToReflectPlaying];
	if (!ruler_drawn&&!need_to_scroll) return self;
	
	// Now we know we have to draw or scroll...

	// we're assuming here that [sender sound] really _is_ a sound,
	// not a soundview.
        st=[(Sound*)snd status];		// TypeCast for OS X server

	if (st!=NX_SoundPlaying && st!=NX_SoundPlayingPending&&
	    st!=NX_SoundPlayingPaused) return self;
	

	samp=[(Sound*)snd samplesProcessed];
	[(ResoundMiscSoundView*)cv getSelection:&fs size:&ns];
	if (ns) samp+=fs;			// this is because the samples processed are
	// how _many_ samples have been processed, NOT
	// the sample numbers in the soundview! 
	
	// disable window flush, display, then reenable flush
	
	[[cv window] disableFlushWindow]; 
	if (need_to_scroll) [cv scrollToSample:samp];
	if (ruler_drawn) [cv setPlayMark:samp];
	[[cv window] enableFlushWindow]; 
	[[cv window] flushWindowIfNeeded];
	
	return self;
#ifndef __BUILDING_RHAPSODY
	}
#endif
    }





/**** clearPlayMark
  Clears the play mark.  Performed at end of playing.
*/

- clearPlayMark
    {
    id cv=[soundManager soundViewPlayingOrRecording];
    
    if (cv==nil) return self;

    // disable window flush, display, then reenable flush
    
    [[cv window] disableFlushWindow]; 
    [cv setPlayMark:-1];
    [[cv window] enableFlushWindow]; 
    [[cv window] flushWindowIfNeeded];
    
    return self;
    }



/**** displayRecordFormatPanel:
  Display the record format panel. Called from a menu item.
*/

- displayRecordFormatPanel:sender
    {
    [formatWindow makeKeyAndOrderFront:sender];
    return self;
    }




/**** setRateToMe:
  Sets the default recording rate.  This can be set by either a text field or by 
  a pop-up menu as shown in the Record panel.
*/

- setRateToMe:sender
    {
    NSString* defaultRate;
    float f;

    if ([sender isKindOf:[NSTextField class]])
	{
	f=[(NSControl*)sender floatValue];
	if (f<=0) f=SND_RATE_CODEC;		// default
	defaultRate=[NSString stringWithFormat:@"%f",f];
	}
    else
    defaultRate=[[sender selectedCell] title];

    {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: defaultRate forKey: @"RecordRate"];
    }
    
    return self;
    }



/**** setFormatToMe:
  Sets the default format.  This is done in the record panel.
*/

- setFormatToMe:sender
    {
    NSString* defaultEncoding;
    int index;
    NXSoundParameterTag *encodings;
    unsigned int n_encodings;

    [sound_device getStreamDataEncodings:&encodings count:&n_encodings];

    index=[[formatMenu menu] indexOfItem:[[formatMenu menu] itemWithTitle:[[sender selectedCell] title]]];

    defaultEncoding=[NSString stringWithFormat:@"%d",index];

    {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: defaultEncoding forKey: @"RecordEncoding"];
    }
    
    return self;
    }




/**** setMono:
  Sets both volume channels.
*/

- setMono:sender
    {
    [sound_device setParameter:NX_SoundDeviceInputGainStereo
   toFloat:[monoRecordGain floatValue]];
    [leftRecordGain setFloatValue: [sound_device floatValueForParameter:
				    NX_SoundDeviceInputGainLeft]];
    [rightRecordGain setFloatValue:[sound_device floatValueForParameter:
				    NX_SoundDeviceInputGainRight]];
    return self;
    }


/**** setLeft:
  Sets the left volume channel.
*/

- setLeft:sender
    {
    [sound_device setParameter:NX_SoundDeviceInputGainLeft
   toFloat:[leftRecordGain floatValue]];
    [rightRecordGain setFloatValue: [sound_device floatValueForParameter:
				     NX_SoundDeviceInputGainRight]];
    [monoRecordGain setFloatValue:[sound_device floatValueForParameter:
				   NX_SoundDeviceInputGainStereo]];
    return self;
    }


/**** setRight:
  Sets the right volume channel.
*/

- setRight:sender
    {
    [sound_device setParameter:NX_SoundDeviceInputGainRight
   toFloat:[rightRecordGain floatValue]];
    [leftRecordGain setFloatValue: [sound_device floatValueForParameter:
				    NX_SoundDeviceInputGainLeft]];
    [monoRecordGain setFloatValue:[sound_device floatValueForParameter:
				   NX_SoundDeviceInputGainStereo]];
    return self;
    }


/**** setMonoChannels:
  Sets the default number of channels to mono.
*/

- setMonoChannels:sender
    {
    NSString* defaultChannel;

    defaultChannel=@"1";

    {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: defaultChannel forKey: @"RecordChannels"];
    }
    
    return self;
    }




/**** setStereoChannels:
  Sets the default number of channels to stereo.
*/


- setStereoChannels:sender
    {
    NSString* defaultChannel;

    defaultChannel=@"2";

    {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: defaultChannel forKey: @"RecordChannels"];
    }
    
    return self;
    }



/**** setSourceMic:
  Sets the default source to the microphone (a PC option).
*/

- setSourceMic:sender
    {
    NSString* defaultSource;

    defaultSource=SOURCE_MIC;

    {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: defaultSource forKey: @"RecordSource"];
    }
    
    return self;
    }




/**** setSourceLine:
  Sets the default source to line-input (a PC option).
*/


- setSourceLine:sender
    {
    NSString* defaultSource;

    defaultSource=SOURCE_LINE;

    {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: defaultSource forKey: @"RecordSource"];
    }
    
    return self;
    }



/**** setRecordingLength:
  Sets the default recording length (the standard is F_LENGTH_5_MINUTES )
*/


- setRecordingLength:sender
    {
    NSString* defaultLength;
    float f=[sender floatValue];

    if (f<=0) f=F_LENGTH_5_MINUTES;	// default (we can't have negatives!)

    defaultLength=[NSString stringWithFormat:@"%f",f];
    [sender setStringValue:defaultLength];

    {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: defaultLength forKey: @"RecordLength"];
    }
    
    return self;
    }



/**** windowDidBecomeKey:
  Set up initial matricies in record window...geez, this is dumb.
  */


- (void)windowDidBecomeKey:sender
/* This is really dumb--because I can't seem to pre-set the matrices,
   I have to set them after the window opens the first time */

    {
    NSString* defaultChannel;
    NSString* defaultSource;

    [sender disableFlushWindow];
    
    // Get Defaults

    {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        defaultChannel = [defaults stringForKey: @"RecordChannels"];
        defaultSource = [defaults stringForKey: @"RecordSource"];
     }

    // Set the Input Source...
    
    if ([defaultSource isEqualToString:SOURCE_LINE])
	[source selectCellAtRow:0 column:0];
    else 
	[source selectCellAtRow:1 column:0];
    

    if ([sound_device streamChannelCountLimit]==1)
	// Warning, bug in NeXT's docs the name is totally wrong...
	{
	[[channels cellAtRow:1 column:0] setEnabled:NO];
	[channels selectCellAtRow:0 column:0];
	defaultChannel=@"1";
	}
    else
	{
	if ([defaultChannel isEqualToString:@"1"])
	    [channels selectCellAtRow:0 column:0];
	else 
	    [channels selectCellAtRow:1 column:0];
	
	}
    [sender enableFlushWindow];
    [sender flushWindowIfNeeded];
    }


@end
