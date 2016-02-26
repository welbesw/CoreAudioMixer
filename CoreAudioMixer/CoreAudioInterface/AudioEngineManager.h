//
//  AudioEngineManager.h
//  CoreAudioMixer
//
//  Created by William Welbes on 2/25/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//
//  Implement CoreAudio functionality using the AVAudioEngine introduced in iOS8


#import <Foundation/Foundation.h>
#import "AudioManager.h"

@interface AudioEngineManager : NSObject <AudioManager>

-(void)loadEngine;
-(void)startPlaying;

-(void)setGuitarInputVolume:(Float32)value;
-(void)setDrumInputVolume:(Float32)value;

@end
