# CoreAudioMixer
An investigation into CoreAudio.

I've implemented this app as part of my investigation into the CoreAudio frameworks on iOS.  It uses two different audio files, one with drums and one with guitar and mixes them together using the AudioToolbox AUGraph via AudioUnit and connections from inputs to outputs.

##User Interface##

![Mixer Screen Shot](/images/mixer-screen-shot-1.png)

The interface for the app is simple.  The audio files and graph are loaded when the app is started.  The user can playback the audio by pressing "Play" and then adjust the volume on the individual tracks via the UISwitch sliders.  Playback can be stopped and started via the "Play/Stop" button.  The output volume level is shown as a percentage to the user.

##Source##
I have implemented all of the CoreAudio calls in a simple Objective-C class that encapsulates the C and Objective-C calls into the CoreAudio frameworks.  This allows the UI elements to simply call into the Objective-C class as needed.  I have implemented the UIViewController and other UI related code in Swift, but Objective-C could have just as easily been used for these classes.

The source is a work in progress and investigational in nature and not intended as production ready code.