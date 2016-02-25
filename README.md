# CoreAudioMixer
An investigation into CoreAudio.

I've implemented this app as part of my investigation into the CoreAudio frameworks on iOS.  It uses two different audio files, one with drums and one with guitar and mixes them together using the AudioToolbox AUGraph via AudioUnit and connections from inputs to outputs.

![Mixer Screen Shot](/images/mixer-screen-shot-1.png =300x)

The interface for the app is simple.  The audio files and graph are loaded when the app is started.  The user can playback the audio by pressing "Play" and then adjust the volume on the individual tracks via the UISwitch sliders.  Playback can be stopped and started via the "Play/Stop" button.  The output volume level is shown as a percentage to the user.