//
//  AudioSessionManager.h
//  CoreAudioMixer
//
//  Created by William Welbes on 2/26/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioSessionManager : NSObject

+(AudioSessionManager*)sharedInstance;

//Call setup audio session before loading files or initializing the graph
-(void)setupAudioSession;

@end
