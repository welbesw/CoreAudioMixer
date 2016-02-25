//
//  CoreAudioManager.m
//  CoreAudioMixer
//
//  Created by William Welbes on 2/24/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

#import "CoreAudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioFormat.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioUnit/AudioUnit.h>

const Float64 kSampleRate = 44100.0;

//Create a struct to store the sound buffer data from sound files loaded

typedef struct {
    AudioStreamBasicDescription asbd;
    Float32 *data;
    UInt32 numberOfFrames;
    UInt32 sampleNumber;
} SoundBuffer, *SoundBufferPtr;

@interface CoreAudioManager() {
    SoundBuffer mSoundBuffer[2];    //TODO - make dynamically sized based on files added
    AVAudioFormat * mAudioFormat;
    
    AUGraph mGraph;
    AudioUnit mMixer;
    AudioUnit mOutput;
}
@end

@implementation CoreAudioManager

+(CoreAudioManager*)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static CoreAudioManager * _sharedManager = nil;
    dispatch_once(&pred, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

-(id)init {
    
    self = [super init];
    if (self != nil) {
        self.isPlaying = NO;
    }
    
    return self;
}

-(void)dealloc {
    
    //Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object:[AVAudioSession sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object:[AVAudioSession sharedInstance]];
    
    //Release allocated memory for sound buffer member
    free(mSoundBuffer[0].data);
    free(mSoundBuffer[1].data);
    
    // clear the mSoundBuffer struct
    memset(&mSoundBuffer, 0, sizeof(mSoundBuffer));
}

-(void)loadAudioFiles {
    NSLog(@"loadAudioFiles");
    
    NSString * guitarSourcePath = [[NSBundle mainBundle] pathForResource:@"GuitarMonoSTP" ofType:@"aif"];
    NSString * drumsSourcePath = [[NSBundle mainBundle] pathForResource:@"DrumsMonoSTP" ofType:@"aif"];
    
    NSArray * sourcePaths = @[guitarSourcePath, drumsSourcePath];
    
    AVAudioFormat * audioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:kSampleRate channels:1 interleaved:YES];
    
    //Loop through each of the source path objects and load the file
    for (int i = 0; i < sourcePaths.count; ++i) {
        
        NSString * sourcePath = sourcePaths[i];
        
        CFURLRef fileUrlRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourcePath, kCFURLPOSIXPathStyle, false);
        
        //Open the audio file
        ExtAudioFileRef extAFref = 0;
        OSStatus result = ExtAudioFileOpenURL(fileUrlRef, &extAFref);
        if (result != 0 || !extAFref) {
            NSLog(@"Error opening audio file.  ExtAudioFileOpenURL result: %ld ", (long)result);
            break;  //Break out of the loop since we hit an error opening (TODO: more handling)
        }
        
        //Get the file data format
        AudioStreamBasicDescription audioFileFormat;
        UInt32 propertySize = sizeof(audioFileFormat);
        
        result = ExtAudioFileGetProperty(extAFref, kExtAudioFileProperty_FileDataFormat, &propertySize, &audioFileFormat);
        if(result != 0) {
            NSLog(@"Error getting file format property. ExtAudioFileGetProperty result: %ld", (long)result);
            break ; //Break out of the loop since we hit an error getting the file format (TODO: more handling)
        }
        
        //Set the format that will be sent to the input of the mixer
        
        double sampleRateRatio = kSampleRate / audioFileFormat.mSampleRate;
        
        propertySize = sizeof(AudioStreamBasicDescription); //Get the basic description property
        
        result = ExtAudioFileSetProperty(extAFref, kExtAudioFileProperty_ClientDataFormat, propertySize, audioFormat.streamDescription);
        if (result != 0) {
            NSLog(@"Error setting audio format property. ExtAudioFileSetProperty result: %ld ", (long)result);
            break; //Break out of the loop since we hit an error setting the format (TODO: more handling)
        }
        
        //Get the files length in frames
        
        UInt64 numberOfFrames = 0;
        propertySize = sizeof(numberOfFrames);
        
        result = ExtAudioFileGetProperty(extAFref, kExtAudioFileProperty_FileLengthFrames, &propertySize, &numberOfFrames);
        if(result != 0) {
            NSLog(@"Error getting number of frames. ExtAudioFileGetProperty result: %ld", (long)result);
            break;  //Break out of the loop since we hit an error getting the number of frames (TODO: more handling)
        }
        
        //Print the number of frames and a converted number of frames based on the sample ratio
        NSLog(@"%u frames in %@", (unsigned int)numberOfFrames, sourcePath.lastPathComponent);
        
        numberOfFrames = numberOfFrames * sampleRateRatio;
        NSLog(@"%u frames after sample ratio multiplied in %@", (unsigned int)numberOfFrames, sourcePath.lastPathComponent);
        
        //Set up the sound buffer
        
        mSoundBuffer[i].numberOfFrames = (UInt32)numberOfFrames;
        mSoundBuffer[i].asbd = *(audioFormat.streamDescription);
        
        //Determine the number of samples by multiplying the number of frames by the number of channels per frame
        UInt32 samples = (UInt32)numberOfFrames * mSoundBuffer[i].asbd.mChannelsPerFrame;
        
        //Allocate memory for a buffer size based on the number of samples
        mSoundBuffer[i].data = (Float32 *)calloc(samples, sizeof(Float32));
        mSoundBuffer[i].sampleNumber = 0;
        
        //Create an AudioBufferList to read into
        AudioBufferList bufferList;
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0].mNumberChannels = 1;
        bufferList.mBuffers[0].mData = mSoundBuffer[i].data;
        bufferList.mBuffers[0].mDataByteSize = samples * sizeof(Float32);
        
        //Read audio data from file into allocated data buffer
        
        //Number of packets is the same as the number of frames we've extracted and calculcated based on sample ratio
        UInt32 numberOfPackets = (UInt32)numberOfFrames;
        
        result = ExtAudioFileRead(extAFref, &numberOfPackets, &bufferList);
        if (result != 0) {
            NSLog(@"Error reading audio file. ExtAudioFileRead result: %ld", (long)result);
            free(mSoundBuffer[i].data);
            mSoundBuffer[i].data = 0;
        }
        
        //Dispose the audio file reference now that is has been read.
        ExtAudioFileDispose(extAFref);
        
        //Release the reference to the file url
        CFRelease(fileUrlRef);
        
    }
}

-(void)setupAudioSession {
    
    AVAudioSession * sessionInstance = [AVAudioSession sharedInstance];
    
    NSError * error = nil;
    
    [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    if(error != nil) {
        NSLog(@"Error setting audio category: %@", error.localizedDescription);
    }
    
    NSTimeInterval bufferDuration = .005;
    [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
    if(error != nil) {
        NSLog(@"Error settting Preferred Buffer Duration: %@", error.localizedDescription);
    }
    
    [sessionInstance setPreferredSampleRate:kSampleRate error:&error];
    if (error != nil) {
        NSLog(@"Error setting preferred sample rate: %@", error.localizedDescription);
    }
    
    
    //Add self as the interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:sessionInstance];
    
    //Add seld as the route change handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRouteChange:) name:AVAudioSessionRouteChangeNotification object:sessionInstance];
    
    
    //Set the session to active
    [sessionInstance setActive:YES error:&error];
    if(error != nil) {
        NSLog(@"Error setting audio session to active: %@", error.localizedDescription);
    } else {
        NSLog(@"AVAudioSession set to active.");
    }
}

-(void)handleInterruption:(NSNotification*)notification {
    
    //Get the type of interruption
    UInt8 interruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"AVAudioSession interrupted: %@", interruptionType == AVAudioSessionInterruptionTypeBegan ? @"Begin Interruption" : @"End Interruption");
    
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        //stop for the interruption
        [self stopPlaying];
        
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        NSError * error = nil;
        
        //Activate the session
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (error != nil) {
            NSLog(@"AVAudioSession setActive failed: %@", error.localizedDescription);
        }
    }
}

-(void)handleRouteChange:(NSNotification*)notification {
    
    //Get the type of route change
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    
     NSLog(@"handleRouteChange: reasonValue: %d", reasonValue);
    
    AVAudioSessionRouteDescription * routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"handleRouteChange: new route: %@", routeDescription);
}

-(void)initializeAUGraph
{
    NSLog(@"initializeAUGraph");
    
    //Create the AUNodes to be used
    AUNode outputNode;
    AUNode mixerNode;
    
    //Setup the audio format for the graph
    mAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                    sampleRate:kSampleRate
                                                      channels:2
                                                   interleaved:NO];
    
    OSStatus result = 0;
    
    //Create a new AUGraph
    result = NewAUGraph(&mGraph);
    if(result != 0) {
        NSLog(@"Error creating via NewAUGraph: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    // create two AudioComponentDescriptions for the AUs we want in the graph
    
    //Output audio unit
    AudioComponentDescription outputDescription;
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputDescription.componentFlags = 0;
    outputDescription.componentFlagsMask = 0;
    
    // Multichannel mixer audio unit
    AudioComponentDescription mixerDescription;
    mixerDescription.componentType = kAudioUnitType_Mixer;
    mixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerDescription.componentFlags = 0;
    mixerDescription.componentFlagsMask = 0;
    
    //Create an audio node in the graph that is an AudioUnit
    result = AUGraphAddNode(mGraph, &outputDescription, &outputNode);
    if (result != 0) {
        NSLog(@"Error adding output node: AUGraphAddNode result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    result = AUGraphAddNode(mGraph, &mixerDescription, &mixerNode);
    if (result != 0) {
        NSLog(@"Error adding mixer node: AUGraphAddNode result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    //Connect the node input and output
    result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, outputNode, 0);
    if (result != 0) {
        NSLog(@"Error connecting node input: AUGraphConnectNodeInput result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    //Open the AudioUnits via the graph
    result = AUGraphOpen(mGraph);
    if (result != 0) {
        NSLog(@"Error opening graph: AUGraphOpen result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    if(result != 0) {
        NSLog(@"Error loading mixer node info: AUGraphNodeInfo result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    result = AUGraphNodeInfo(mGraph, outputNode, NULL, &mOutput);
    if(result != 0) {
        NSLog(@"Error loading output node info: AUGraphNodeInfo result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    //Setup 2 buses
    UInt32 numbuses = 2;
    
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, sizeof(numbuses));
    if(result != 0) {
        NSLog(@"Error setting audio unit property on mixer: %ld", (long)result);
    }
    
    for (int i = 0; i < numbuses; ++i) {
        // setup render callback struct
        AURenderCallbackStruct renderCallbackStruct;
        renderCallbackStruct.inputProc = &renderAudioInput;
        renderCallbackStruct.inputProcRefCon = mSoundBuffer;
        
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback(mGraph, mixerNode, i, &renderCallbackStruct);
        if(result != 0) {
            NSLog(@"AUGraphSetNodeInputCallback failed with result: %ld", (long)result);
            return;     //Short circuit out - TODO: better error handling
        }
        
        //Set the input stream format property
        result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
        if(result != 0) {
            NSLog(@"AudioUnitSetProperty failed with result: %ld", (long)result);
            return;     //Short circuit out - TODO: better error handling
        }
    }
    
    //Set the output stream format property
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
    if(result != 0) {
        NSLog(@"AudioUnitSetProperty mixer stream format failed with result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    result = AudioUnitSetProperty(mOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
    if(result != 0) {
        NSLog(@"AudioUnitSetProperty output stream format failed with result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
    
    //Initialize the graph
    result = AUGraphInitialize(mGraph);
    if(result != 0) {
        NSLog(@"AUGraphInitialize failed with result: %ld", (long)result);
        return;     //Short circuit out - TODO: better error handling
    }
}

//A static audio render method callback that will be used by the AURenderCallback from the AUGraph
static OSStatus renderAudioInput(void *inRefCon, AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberOfFrames, AudioBufferList *ioData)
{
    SoundBufferPtr soundBuffer = (SoundBufferPtr)inRefCon;
    
    //Get the frame to start at and total number of samples
    UInt32 sample = soundBuffer[inBusNumber].sampleNumber;
    UInt32 bufferTotalSamples = soundBuffer[inBusNumber].numberOfFrames;
    
    //Get a reference to the input data buffer
    Float32 *inputData = soundBuffer[inBusNumber].data; // audio data buffer
    
    //Get references to the channel buffers
    Float32 *outLeft = (Float32 *)ioData->mBuffers[0].mData; // output audio buffer for Left channel
    Float32 *outRight = (Float32 *)ioData->mBuffers[1].mData; // output audio buffer for Right channel
    
    //Loop thru the number of frames and set the output data from the input data.
    //Use the left channel for bus 0 (guitar) and right channel for bus 1 (drums) to distiguish for example
    for (UInt32 i = 0; i < inNumberOfFrames; ++i) {
        
        if (inBusNumber == 0) {
            outLeft[i] = inputData[sample++];
            outRight[i] = 0;
        } else {    //inBusNumber == 1
            outLeft[i] = 0;
            outRight[i] = inputData[sample++];
        }
        
        //If the sample is beyond the total number of samples in the loop, start over at the beginning
        if (sample > bufferTotalSamples) {
            // start over from the beginning of the data, our audio simply loops
            sample = 0;
            NSLog(@"Starting over at frame 0 for bus %d", (int)inBusNumber);
        }
    }
    
    //Set the sample number in the sound buffer struct so we know which frame playback is on
    soundBuffer[inBusNumber].sampleNumber = sample;
    
    return noErr;
}

-(void)startPlaying {
    NSLog(@"startPlaying");
    
    OSStatus result = AUGraphStart(mGraph);
    if(result != 0) {
        NSLog(@"AUGraphStart failed: %ld", (long)result);
        return;
    }
    
    self.isPlaying = YES;
}

-(void)stopPlaying {
    NSLog(@"stopPlaying");
    
    Boolean isRunning = false;
    
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    if(result != 0) {
        NSLog(@"AUGraphIsRunning failed: %ld", (long)result);
        return;
    }
    
    if(isRunning) {
        result = AUGraphStop(mGraph);
        if(result != 0) {
            NSLog(@"AUGraphStop failed: %ld", (long)result);
            return;
        }
        self.isPlaying = NO;
    } else {
        NSLog(@"AUGraphIsRunning reported not running.");
    }
}

-(void)setVolumeForInput:(UInt32)inputIndex value:(AudioUnitParameterValue)value {
    
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputIndex, value, 0);
    if(result != 0) {
        NSLog(@"AudioUnitSetParameter failed when setting input volume: %ld", (long)result);
    }
}

-(void)setGuitarInputVolume:(Float32)value {
    [self setVolumeForInput:0 value:value];
}

-(void)setDrumInputVolume:(Float32)value {
    [self setVolumeForInput:1 value:value];
}

@end
