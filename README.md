# CoreAudioMixer

## An Investigation into CoreAudio

I've implemented this app as part of my investigation into the CoreAudio frameworks on iOS.  It uses two different audio files, one with drums and one with guitar and mixes them together.   

There are two different implementations of interfacing with CoreAudio. First with AudioToolbox using AUGraph and second with [AVAudioEngine](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVAudioEngine_Class/index.html), Apple's newer audio API released with iOS 8.  There is a segmented control that allows the user to select which implementation to interact with.

For more about CoreAudio, visit the iOS [CoreAudio Apple Developer Library](https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/CoreAudioOverview/CoreAudioEssentials/CoreAudioEssentials.html).

## User Interface

![Mixer Screen Shot](/images/mixer-screen-shot-1.png)

The interface for the app is simple.  Select an implementation type via the segmented control at the top.  Press "Play" and then adjust the volume on the individual tracks via the sliders.  Playback can be stopped and started via the "Play/Stop" button.  The output volume level is shown as a percentage.  The guitar is output to the left channel and the drums are output to the right channel.

I've also added a frequency spectrum view into the interface that shows the frequency information in real time for the Guitar track as it plays.  This view simply uses UIViews as columns to represent the data.  For a more robust view an OpenGL view could be explored in the future.  The FFT is only performed in the CoreAudioManager that implements the AUGraph, so it is not displayed when the AVAudioEngine implementation is selected in the UI.

## Source

The implementation of CoreAudio calls is contained in two separate manager classes: CoreAudioManager and AudioEngineManager.  

* CoreAudioManager : AudioToolbox API (lower level API)
* AudioEngineManager : AVAudioEngine implementation

CoreAudioManager contains the CoreAudio calls in a simple Objective-C class that encapsulates the C and Objective-C calls into the CoreAudio frameworks.  This allows the UI elements to simply call into the Objective-C class as needed.  I have implemented the UIViewController and other UI related code in Swift, but Objective-C could have just as easily been used for these classes.

The CoreAudioManager class also contains an implementation of the Fast Fourier Transform (FFT) via Apple's [Accelerate Framework](https://developer.apple.com/library/prerelease/ios/documentation/Accelerate/Reference/vDSPRef/index.html#//apple_ref/doc/uid/TP40009464) to transform the time based audio data into frequency spectrum data in real time as the track is being played back.  The FFT is implemented as a call within the AURenderCallback method.  It takes the current window of the data buffer that the render callback is operating on and applies the vDSP_fft_zrip method from the Accelerate framework to quickly and efficiently transform the data into real and imaginary pairs.  The buffer of data is then stored to be used for display as requested by the UI.  It's worth noting that the FFT is performed for both tracks while playing, but the UI is currently only displaying the Guitar track data.  The display of the spectrum data is showing the whole audio range from 0 to 22kHz on a linear scale, so the frequency data tends to be centered around the low end of the output display.  In the future, improvements to the display could be made to more evenly show the frequency values of interest.

One interesting issue that I encountered when implementing AVAudioEngine, is that it appears that there is not currently an easy way to guarantee that the tracks loaded will play at exactly the same time and be synced correclty.  In my testing, it seems that they are in sync, but this seems to be a gap in the AVAudioEngine implementation at the moment.  The following thread on the Apple Developer Forums describes the issue: 

https://forums.developer.apple.com/thread/14138

The source is a work in progress and investigational in nature and not intended as production ready code.
