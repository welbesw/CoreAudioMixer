//
//  CoreAudioManager.h
//  CoreAudioMixer
//
//  Created by William Welbes on 2/24/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioManager.h"

extern const Float64 kSampleRate;

@interface CoreAudioManager : NSObject <AudioManager>

-(void)loadAudioFiles;
-(void)initializeAUGraph;

-(void)startPlaying;
-(void)stopPlaying;

-(void)setGuitarInputVolume:(Float32)value;
-(void)setDrumInputVolume:(Float32)value;

-(Float32*)guitarFrequencyDataOfLength:(UInt32*)size;
-(Float32*)drumsFrequencyDataOfLength:(UInt32*)size;

@end
