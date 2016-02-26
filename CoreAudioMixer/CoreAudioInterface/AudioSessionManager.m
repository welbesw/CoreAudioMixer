//
//  AudioSessionManager.m
//  CoreAudioMixer
//
//  Created by William Welbes on 2/26/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

#import "AudioSessionManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioSessionManager

+(AudioSessionManager*)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static AudioSessionManager * _sharedManager = nil;
    dispatch_once(&pred, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
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
    
    [sessionInstance setPreferredSampleRate:44100.0 error:&error];
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
        //Tell audio managers to stop playing!
        [[NSNotificationCenter defaultCenter] postNotificationName:@"StopAudioNotification" object:nil];
        
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


@end
