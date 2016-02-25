//
//  CoreAudioManager.h
//  CoreAudioMixer
//
//  Created by William Welbes on 2/24/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const Float64 kSampleRate;


@interface CoreAudioManager : NSObject

+(CoreAudioManager*)sharedInstance;

@property(nonatomic, assign) BOOL isPlaying;

//Call setup audio session before loading files or initializing the graph
-(void)setupAudioSession;

-(void)loadAudioFiles;
-(void)initializeAUGraph;

-(void)startPlaying;
-(void)stopPlaying;

-(void)setGuitarInputVolume:(Float32)value;
-(void)setDrumInputVolume:(Float32)value;

@end
