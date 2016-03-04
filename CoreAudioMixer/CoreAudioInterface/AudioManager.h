//
//  AudioManager.h
//  CoreAudioMixer
//
//  Created by William Welbes on 2/25/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioManager <NSObject>

-(void)load;

-(void)startPlaying;
-(void)stopPlaying;

-(BOOL)isPlaying;

-(void)setGuitarInputVolume:(Float32)value;
-(void)setDrumInputVolume:(Float32)value;

-(Float32*)guitarFrequencyDataOfLength:(UInt32*)size;
-(Float32*)drumsFrequencyDataOfLength:(UInt32*)size;

@end
