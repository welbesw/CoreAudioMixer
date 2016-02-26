# CoreAudioMixer
An investigation into CoreAudio.

I've implemented this app as part of my investigation into the CoreAudio frameworks on iOS.  It uses two different audio files, one with drums and one with guitar and mixes them together.   I've implemented CoreAudio in two different ways, first with AudioToolbox using AUGraph and secondly with AVAudioEngine, Apple's newer Audio SDK released with iOS 8.  There is a segmented control that allows the user to select which implementation to play.


##User Interface##

![Mixer Screen Shot](/images/mixer-screen-shot-1.png)

The interface for the app is simple.  The audio files and graph are loaded when the app is started or when the user selects a different implementation via changing the segmented control option.  The user can playback the audio by pressing "Play" and then adjust the volume on the individual tracks via the UISwitch sliders.  Playback can be stopped and started via the "Play/Stop" button.  The output volume level is shown as a percentage to the user.  The guitar is output to the left channel and the drums are output to the right channel.

##Source##

The implementation of CoreAudio calls is contained in two separate manager classes: CoreAudioManager and AudioEngineManager.  CoreAudioManager is an implementation using the AudioToolbox API directly and at a lower level than the AudioEngineManager.  The AudioEngineManager implements Apple's newer AVAudioEngine API.

CoreAudioManager contains the CoreAudio calls in a simple Objective-C class that encapsulates the C and Objective-C calls into the CoreAudio frameworks.  This allows the UI elements to simply call into the Objective-C class as needed.  I have implemented the UIViewController and other UI related code in Swift, but Objective-C could have just as easily been used for these classes.

One interesting issue that I encountered when implementing AVAudioEngine, is that it appears that there is not currently an easy way to guarantee that the tracks loaded will play at exactly the same time and be synced correclty.  In my testing, it seems that they are in sync, but this seems to be a gap in the AVAudioEngine implementation at the moment.  The following thread on the Apple Developer Forums describes the issue: 

https://forums.developer.apple.com/thread/14138

The source is a work in progress and investigational in nature and not intended as production ready code.