/*
MiscSoundTracker
Version 2.0.2
Copyright (c) 1995, 1998 by Sean Luke
OpenStep / Rhapsody port
Copyright (c) 1998 by Jerome Genest
Donated to the MiscKit

Permission to use, copy, modify, and distribute this material 
for any purpose and without fee, under the restrictions as noted 
in the MiscKit copyright notice, is hereby granted, provided that
the MiscKit copyright notice and this permission notice 
appear in all source copies, and that the authors names shall not
be used in advertising or publicity pertaining to this 
material without the specific, prior written permission 
of the author.  SEAN O. LUKE AMD JEROME GENEST  MAKE NO REPRESENTATIONS 
ABOUT THE ACCURACY OR SUITABILITY OF THIS MATERIAL FOR ANY PURPOSE.  
IT IS PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.

*/

#import "MiscSoundTracker.h"
#import <stdio.h>

@implementation MiscSoundTracker

// KNOWN BUGS:  NeXT's sound object does not release sampling rate information
// properly.  Hence, the tracker cannot get seconds information correctly,
// when recording, and so must rely on a preset default for its sampling
// rate in returning seconds.

// also, samples do not keep up with pausing.



- init
	{
	[super init];
	running=NO;
	default_sampling_rate=SOUNDTRACKER_DEFAULT_SAMPLING_RATE;
	send_type=SOUNDTRACKER_SEND_TYPE_SAMPLES;
	refresh=SOUNDTRACKER_TIMED_ENTRY_SPEED;
	//printf ("Init\n");
	return self;
	}

- _update
	{
	//printf("Updating\n");
	
	// first we check to see if there's a sound lock and if so,
	// if we should proceed...
	
	if (sound!=nil&&
			(send_type==SOUNDTRACKER_SEND_TYPE_SAMPLES||
			send_type==SOUNDTRACKER_SEND_TYPE_RATIO||
			send_type==SOUNDTRACKER_SEND_TYPE_PERCENT||
			send_type==SOUNDTRACKER_SEND_TYPE_SECONDS))
			{
			id actual_sound;
			int status;
			
			if ([sound isKindOfClass:[Sound class]]) 
				{actual_sound=sound;}
			else if ([sound isKindOfClass:[SoundView class]])
				{actual_sound=[sound soundBeingProcessed];}
			else return nil;		// not a sound or soundview!!!
			
                        status=[(Sound*)actual_sound status];	// TypeCast for OS X server
			if (status==NX_SoundStopped||
				status==NX_SoundInitialized||
				status==NX_SoundFreed) return self;		
					// sound's not doing anything...
			}
	
	if (target!=nil)
		{
		//printf ("Target Not nil\n");
        if (send_type==SOUNDTRACKER_SEND_TYPE_SAMPLES||
            send_type==SOUNDTRACKER_SEND_TYPE_MUTE||		send_type==SOUNDTRACKER_SEND_TYPE_MUTE_SPEAKER||
            send_type==SOUNDTRACKER_SEND_TYPE_MUTE_LINE_OUT||
            send_type==SOUNDTRACKER_SEND_TYPE_MUTE_HEADPHONES||
            send_type==SOUNDTRACKER_SEND_TYPE_RAMPING||
			send_type==SOUNDTRACKER_SEND_TYPE_DEEMPHASIS)
			{
			//printf ("Sending Take Message\n");
			if (![target respondsToSelector:@selector(takeIntValueFrom:)])
				 return nil;
			[target takeIntValueFrom:self];
			}
		else if (send_type==SOUNDTRACKER_SEND_TYPE_RATIO||
				send_type==SOUNDTRACKER_SEND_TYPE_PERCENT)
			{
                	int status=[(Sound*)sound status];	// TypeCast for OS X server
			if (status==NX_SoundRecording||
				status==NX_SoundRecordingPaused)
				{
				[self clearTarget];
				}
			else
				{
				if (![target respondsToSelector:@selector(takeFloatValueFrom:)])
					return nil;
				[target takeFloatValueFrom:self];
				}
			}
		else if (send_type==SOUNDTRACKER_SEND_TYPE_SECONDS||
				send_type==SOUNDTRACKER_SEND_TYPE_LEFT||
				send_type==SOUNDTRACKER_SEND_TYPE_RIGHT||
				send_type==SOUNDTRACKER_SEND_TYPE_MONO||
           send_type==SOUNDTRACKER_SEND_TYPE_MONITOR_ATTENUATION)
			{
			if (![target respondsToSelector:@selector(takeFloatValueFrom:)])
				 return nil;
			[target takeFloatValueFrom:self];
			}
		else printf ("SOUNDTRACKER Error:  No Send Type\n");
		}
	return self;
	}


- setRefresh:(float) number_seconds
	{
	if (number_seconds>0)
		{
		refresh=number_seconds;
		if (teNum) 
			{
			[teNum invalidate]; 
			[teNum release];
			
			teNum = [[NSTimer timerWithTimeInterval:refresh 
							 target:self selector: @selector(SOUNDTRACKER_update_tracker:)
						       userInfo:(void*) nil 
							repeats:YES] retain];
        		   [[NSRunLoop currentRunLoop] addTimer:teNum forMode: NSDefaultRunLoopMode];  
			}
		}
	return self;
	}

- setRefreshToMe:sender
	{
	if ([sender respondsToSelector:@selector(floatValue)])
		[self setRefresh:[sender floatValue]];
	return self;
	}


- (float)refresh
	{
	return refresh;
	}	

- (void)dealloc
	{
	if (output_device!=nil) [output_device release];
	if (teNum) [teNum invalidate]; [teNum release];
	if (sound!=nil) [sound release];
	if (target!=nil) [target release];
	{ [super dealloc]; return; };
	}


- (void)setSound:(Sound *)this_sound_or_soundview
	{
	if (sound!=nil) [sound release];
	sound=[this_sound_or_soundview retain];
	}
	

- sound
	{
	return sound;
	}

- setDefaultSamplingRate:(float) this_rate
	{
	if (this_rate!=0.0) default_sampling_rate=this_rate;
	return self;
	}

- (float)defaultSamplingRate
	{
	return default_sampling_rate;
	}
	
- (void)setTarget:this_target
	{
	if (target!=nil) [target release];
	target=[this_target retain];
	}


- target
	{
	return target;
	}

- clearTarget
        {
        if ([target respondsToSelector:@selector(setStringValue:)])
                {
                [target setStringValue:@""];
                }
        else [target setIntValue:0];
        return self;
        }

- (id)initWithCoder:(NSCoder *)aDecoder
        {
        //self = [super initWithCoder:aDecoder];  // NSObject Does not respont to initWithCoder
        [aDecoder decodeValuesOfObjCTypes:"iff",&send_type,&refresh,&default_sampling_rate];
        
	running=NO;
        teNum=0;
	return self;
        }

- (void)encodeWithCoder:(NSCoder *)aCoder
        {
        //[super encodeWithCoder:aCoder];  // NSObject Does not respond to encodeWithCoder
        [aCoder encodeValuesOfObjCTypes:"iff",&send_type,&refresh,&default_sampling_rate];
}

- (void)run
	{
	running=YES;
	if (!teNum) 
	{
	teNum = [[NSTimer timerWithTimeInterval:refresh 
					 target: self
			 	       selector: @selector(SOUNDTRACKER_update_tracker:)
 				       userInfo:(void*) self 
					repeats:YES] retain];
           [[NSRunLoop currentRunLoop] addTimer:teNum forMode: NSDefaultRunLoopMode]; 
	}
}


- stop
	{
	running=NO;
	if (teNum) 
	    	{
		[teNum invalidate]; 
		[teNum release];
		}
	teNum=0;
	return self;
	}


- sendSamples
	{
	send_type=SOUNDTRACKER_SEND_TYPE_SAMPLES;
	return self;
	}


- sendSeconds
	{
	send_type=SOUNDTRACKER_SEND_TYPE_SECONDS;
	return self;
	}


- sendRatio
	{
	send_type=SOUNDTRACKER_SEND_TYPE_RATIO;
	return self;
	}
	
- sendPercent
	{
	send_type=SOUNDTRACKER_SEND_TYPE_PERCENT;
	return self;
	}
	
- sendLeft
	{
	send_type=SOUNDTRACKER_SEND_TYPE_LEFT;
	return self;
	}
	

- sendRight
	{
	send_type=SOUNDTRACKER_SEND_TYPE_RIGHT;
	return self;
	}
	

- sendMono
	{
	send_type=SOUNDTRACKER_SEND_TYPE_MONO;
	return self;
	}
	

- sendMute
	{
	send_type=SOUNDTRACKER_SEND_TYPE_MUTE;
	return self;
	}
	
- sendDeemphasis
	{
	send_type=SOUNDTRACKER_SEND_TYPE_DEEMPHASIS;
	return self;
	}

- sendLeftPeak
	{
	send_type=SOUNDTRACKER_SEND_TYPE_LEFT_PEAK;
	return self;
	}

- sendRightPeak
	{
	send_type=SOUNDTRACKER_SEND_TYPE_RIGHT_PEAK;
	return self;
	}
	
- sendMonoPeak
	{
	send_type=SOUNDTRACKER_SEND_TYPE_MONO_PEAK;
	return self;
	}

- sendSpeakerMute	{
    send_type=SOUNDTRACKER_SEND_TYPE_MUTE_SPEAKER;
    return self;
    }

- sendLineOutMute	{
    send_type=SOUNDTRACKER_SEND_TYPE_MUTE_LINE_OUT;
    return self;
    }

- sendHeadphoneMute	{
    send_type=SOUNDTRACKER_SEND_TYPE_MUTE_HEADPHONES;
    return self;
    }

- sendRamping	{
    send_type=SOUNDTRACKER_SEND_TYPE_RAMPING;
    return self;
    }

- sendMonitorAttenuation	{
    send_type=SOUNDTRACKER_SEND_TYPE_MONITOR_ATTENUATION;
    return self;
    }

- setSendType:(int)this_format
	{
	if (this_format==SOUNDTRACKER_SEND_TYPE_SAMPLES||
		this_format==SOUNDTRACKER_SEND_TYPE_SECONDS||
		this_format==SOUNDTRACKER_SEND_TYPE_RATIO||
		this_format==SOUNDTRACKER_SEND_TYPE_PERCENT||
		this_format==SOUNDTRACKER_SEND_TYPE_LEFT||
		this_format==SOUNDTRACKER_SEND_TYPE_RIGHT||
		this_format==SOUNDTRACKER_SEND_TYPE_MONO||
		this_format==SOUNDTRACKER_SEND_TYPE_MUTE||
		this_format==SOUNDTRACKER_SEND_TYPE_DEEMPHASIS||
		this_format==SOUNDTRACKER_SEND_TYPE_LEFT_PEAK||
     this_format==SOUNDTRACKER_SEND_TYPE_RIGHT_PEAK||
     this_format==SOUNDTRACKER_SEND_TYPE_MONO_PEAK||
     this_format==SOUNDTRACKER_SEND_TYPE_MUTE_SPEAKER||
     this_format==SOUNDTRACKER_SEND_TYPE_MUTE_LINE_OUT||
     this_format==SOUNDTRACKER_SEND_TYPE_MUTE_HEADPHONES||
     this_format==SOUNDTRACKER_SEND_TYPE_RAMPING||
     this_format==SOUNDTRACKER_SEND_TYPE_MONITOR_ATTENUATION)
		{send_type=this_format;return self;}
	return nil;
	}

- (int) sendType
	{
	return send_type;
	}

- (float) floatValue	
	{
	if (send_type==SOUNDTRACKER_SEND_TYPE_SECONDS)
		{
		if (sound!=nil)
			{
			if ([sound isKindOfClass:[Sound class]])
				{
				float n=[sound samplingRate];
				//printf ("%f\n",n);
				if (n==0.0) n=default_sampling_rate;
				return ((float)[sound samplesProcessed])/n;
				}
			else if ([sound isKindOfClass:[SoundView class]])
				{
				id snd1=[sound soundBeingProcessed];
				float n=[snd1 samplingRate];
				//printf ("%f\n",n);
				if (n==0.0) n=default_sampling_rate;
				return ((float)[snd1 samplesProcessed])/n;
				}
			}
		}
	else if (send_type==SOUNDTRACKER_SEND_TYPE_RATIO)
		{
		if (sound!=nil)
			{
			if ([sound isKindOfClass:[Sound class]])
				{
				//int status=[sound status];  // no use right now
									
				return ((float)[sound samplesProcessed])/
					((float)[sound sampleCount]);
				}
			else if ([sound isKindOfClass:[SoundView class]])
				{
				id snd1=[sound soundBeingProcessed];
				//int status=[snd1 status];  // no use right now
					
				return ((float)[snd1 samplesProcessed])/
					((float)[snd1 sampleCount]);
				}
			}
		}
	else if (send_type==SOUNDTRACKER_SEND_TYPE_PERCENT)
		{
		if (sound!=nil)
			{
			if ([sound isKindOfClass:[Sound class]])
				{
				//int status=[sound status];  // no use right now
									
				return ((float)[sound samplesProcessed])/
					((float)[sound sampleCount])*100;
				}
			else if ([sound isKindOfClass:[SoundView class]])
				{
				id snd1=[sound soundBeingProcessed];
				//int status=[snd1 status];  // no use right now
					
				return ((float)[snd1 samplesProcessed])/
					((float)[snd1 sampleCount])*100;
				}
			}
		}
	else if (send_type==SOUNDTRACKER_SEND_TYPE_LEFT)
		{
		float l,r;
		[Sound getVolume:&l:&r];
		return l;
		}
	else if (send_type==SOUNDTRACKER_SEND_TYPE_RIGHT)
		{
		float l,r;
		[Sound getVolume:&l:&r];
		return r;
		}
	else if (send_type==SOUNDTRACKER_SEND_TYPE_MONO)
		{
		float l,r;
		[Sound getVolume:&l:&r];
		return (l+r)/2.0;
		}
    else if (send_type==SOUNDTRACKER_SEND_TYPE_MONITOR_ATTENUATION)
        {
        // try to grab resources
        if (output_device==NULL) output_device=[[NXSoundOut alloc] init];

        if (output_device!=NULL)
            {
            return [output_device
                floatValueForParameter:NX_SoundDeviceMonitorAttenuation];
            }
        else return -1.0;
        }
	else if (send_type==SOUNDTRACKER_SEND_TYPE_LEFT_PEAK)
		{
		float l,r;
		
		// try to grab resources
		if (output_device==nil) output_device=[[NXSoundOut alloc] init];
		
		if (output_device!=nil)
			{
			[output_device getPeakLeft:&l right:&r];
			return l;
			}
		// else...return -1.0 as shown below
		}
	else if (send_type==SOUNDTRACKER_SEND_TYPE_RIGHT_PEAK)
		{
		float l,r;
		
		// try to grab resources
		if (output_device==nil) output_device=[[NXSoundOut alloc] init];
		
		if (output_device!=nil)
			{
			[output_device getPeakLeft:&l right:&r];
			return r;
			}
		// else...return -1.0 as shown below
		}
	else if (send_type==SOUNDTRACKER_SEND_TYPE_MONO_PEAK)
		{
		float l,r;
		
		// try to grab resources
		if (output_device==nil) output_device=[[NXSoundOut alloc] init];
		
		if (output_device!=nil)
			{
			[output_device getPeakLeft:&l right:&r];
			return (l+r)/2.0;
			}
		// else...return -1.0 as shown below
		}

	else printf ("SOUNDTRACKER Error:  Wrong send type for floatValue\n");
	return -1.0;
	}


- (int) intValue	
	{
	//printf ("Okay\n");
	if (send_type==SOUNDTRACKER_SEND_TYPE_SAMPLES)
		{
		if (sound!=nil)
			{
			if ([sound isKindOfClass:[Sound class]])
				{
				return [sound samplesProcessed];
				}
			else if ([sound isKindOfClass:[SoundView class]])
				{
				id snd1=[sound soundBeingProcessed];
				return [snd1 samplesProcessed];
				}
			}
		}
	else if (send_type==SOUNDTRACKER_SEND_TYPE_MUTE)
		{
		return (int) [Sound isMuted];
		}
    else if (send_type==SOUNDTRACKER_SEND_TYPE_MUTE_SPEAKER)
        {
        // try to grab resources
        if (output_device==NULL) output_device=[[NXSoundOut alloc] init];

        if (output_device!=NULL)
            {
            return (int) [output_device
                        boolValueForParameter:NX_SoundDeviceMuteSpeaker];
            }
        else return NO;
        }
    else if (send_type==SOUNDTRACKER_SEND_TYPE_MUTE_LINE_OUT)
        {
        // try to grab resources
        if (output_device==NULL) output_device=[[NXSoundOut alloc] init];

        if (output_device!=NULL)
            {
            return (int) [output_device
                        boolValueForParameter:NX_SoundDeviceMuteLineOut];
            }
        else return NO;
        }
    else if (send_type==SOUNDTRACKER_SEND_TYPE_MUTE_HEADPHONES)
        {
        // try to grab resources
        if (output_device==NULL) output_device=[[NXSoundOut alloc] init];

        if (output_device!=NULL)
            {
            return (int) [output_device
                        boolValueForParameter:NX_SoundDeviceMuteHeadphone];
            }
        else return NO;
        }
    else if (send_type==SOUNDTRACKER_SEND_TYPE_RAMPING)
        {
        // try to grab resources
        if (output_device==NULL) output_device=[[NXSoundOut alloc] init];

        if (output_device!=NULL)
            {
            return (int) ([output_device
                        boolValueForParameter:NX_SoundDeviceRampUp]
                        &&[output_device
                        boolValueForParameter:NX_SoundDeviceRampDown]);
            }
        else return NO;
        }
	else if (send_type==SOUNDTRACKER_SEND_TYPE_DEEMPHASIS)
		{
		// try to grab resources
		if (output_device==nil) output_device=[[NXSoundOut alloc] init];
		
		if (output_device!=nil)
			{
			return (int) [output_device doesDeemphasize];
			}
		else return NO;
		}
	else printf ("SOUNDTRACKER Error:  Wrong send type for intValue\n");
	return -1;
	}


- setVolumeTo:sender	
	{
	float l,r,x;
	[Sound getVolume:&l:&r];
	if (! [sender respondsToSelector:@selector(floatValue)]) return nil;
	x=[sender floatValue];
	if (x<0||x>1) return nil;
	if (send_type==SOUNDTRACKER_SEND_TYPE_LEFT) [Sound setVolume:x:r];
	if (send_type==SOUNDTRACKER_SEND_TYPE_RIGHT) [Sound setVolume:l:x];
	if (send_type==SOUNDTRACKER_SEND_TYPE_MONO) [Sound setVolume:x:x];
    if (send_type==SOUNDTRACKER_SEND_TYPE_MONITOR_ATTENUATION)
        {
        // try to grab resources
        if (output_device==NULL) output_device=[[NXSoundOut alloc] init];

        if (output_device!=NULL)
            {
            [output_device setParameter:NX_SoundDeviceMonitorAttenuation
                toFloat:x];
            }
        }
	return self;
	}


- setMuteTo:sender	
    {
    int x;
    if (! [sender respondsTo:@selector(intValue)]) return NULL;
    x=[sender intValue];
    if (x!=0) x=1;

    // try to grab resources
    if (output_device==NULL) output_device=[[NXSoundOut alloc] init];

    if (send_type==SOUNDTRACKER_SEND_TYPE_MUTE) [Sound setMute:(BOOL)x];
    if (send_type==SOUNDTRACKER_SEND_TYPE_MUTE_SPEAKER)
        {
        if (output_device!=NULL)
            {
            [output_device setParameter:NX_SoundDeviceMuteSpeaker
                toBool:x];
            }
        }	
    if (send_type==SOUNDTRACKER_SEND_TYPE_MUTE_LINE_OUT)
        {
        if (output_device!=NULL)
            {
            [output_device setParameter:NX_SoundDeviceMuteLineOut
                toBool:x];
            }
        }	
    if (send_type==SOUNDTRACKER_SEND_TYPE_MUTE_HEADPHONES)
        {
        if (output_device!=NULL)
            {
            [output_device setParameter:NX_SoundDeviceMuteHeadphone
                toBool:x];
            }
        }	
    return self;
    }

- setDeemphasisTo:sender	
	{
	int x;
	if (! [sender respondsToSelector:@selector(intValue)]) return nil;
	x=[sender intValue];
	if (x!=0) x=1;
	
	// try to grab resources
	if (output_device==nil) output_device=[[NXSoundOut alloc] init];
	
	if (output_device!=nil)
		{
		[output_device setDeemphasis:x];
		}
	return self;
	}


- setRampingTo:sender	
    {
    int x;
    if (! [sender respondsTo:@selector(intValue)]) return NULL;
    x=[sender intValue];
    if (x!=0) x=1;

    // try to grab resources
    if (output_device==NULL) output_device=[[NXSoundOut alloc] init];

    if (output_device!=NULL)
        {
        [output_device setParameter:NX_SoundDeviceRampUp
                toBool:x];
        [output_device setParameter:NX_SoundDeviceRampDown
                toBool:x];
        }
    return self;
    }

- (void)run:(id)sender
	{
	[self run];
	//return self;
	}


- (void)stop:(id)sender;
	{
	[self stop];
	}


- sendSamples:sender
	{
	return [self sendSamples];
	}


- sendSeconds:sender
	{
	return [self sendSeconds];
	}


- sendRatio:sender
	{
	return [self sendRatio];
	}

- sendPercent:sender
	{
	return [self sendPercent];
	}

- sendLeft:sender
	{
	return [self sendLeft];
	}

- sendRight:sender
	{
	return [self sendRight];
	}

- sendMono:sender
	{
	return [self sendMono];
	}

- sendMute:sender
	{
	return [self sendMute];
	}
	
- sendDeemphasis:sender
	{
	return [self sendDeemphasis];
	}
	
- sendLeftPeak:sender
	{
	return [self sendLeftPeak];
	}
	
- sendRightPeak:sender
	{
	return [self sendRightPeak];
	}	
	
- sendMonoPeak:sender
	{
	return [self sendMonoPeak];
	}

- sendSpeakerMute:sender
    {
    return [self sendSpeakerMute];
    }

- sendLineOutMute:sender
    {
    return [self sendLineOutMute];
    }

- sendHeadphoneMute:sender
    {
    return [self sendHeadphoneMute];
    }

- sendRamping:sender
    {
    return [self sendRamping];
    }

- sendMonitorAttenuation:sender
    {
    return [self sendMonitorAttenuation];
    }

- (NSString *)inspectorClassName
	{
	return @"MiscSoundTrackerInspector";
	}

// timed entry procedure for periodically updating
// This is called periodically when the NSTimer is Fired

-(void) SOUNDTRACKER_update_tracker: (id) theTimer
       {
       [self _update];
       }

@end






