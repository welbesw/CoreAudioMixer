//
//  ViewController.swift
//  CoreAudioMixer
//
//  Created by William Welbes on 2/24/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var drumSlider:UISlider!
    @IBOutlet var guitarSlider:UISlider!
    
    @IBOutlet var drumLabel:UILabel!
    @IBOutlet var guitarLabel:UILabel!
    
    @IBOutlet var playButton:UIButton!
    
    @IBOutlet var segmentedControl:UISegmentedControl!
    
    var drumLevel:Float = 1.0
    var guitarLevel:Float = 1.0
    
    var audioManager:AudioManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load the core audio manager and initialize the graph
        
        //Start with the CoreAudioManager as the default
        audioManager = CoreAudioManager()
        audioManager.load()
        
        drumSlider.value = drumLevel
        guitarSlider.value = guitarLevel
        updateSliderLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didChangeSegmentedControlValue(sender:UISegmentedControl?) {
        if sender == segmentedControl {
            //Stop any audio before changing managers
            audioManager.stopPlaying()
            updatePlayButtonText()
            
            let index = segmentedControl.selectedSegmentIndex
            if index == 0 {
                audioManager = CoreAudioManager()
                audioManager.load()
            } else if (index == 1) {
                audioManager = AudioEngineManager()
                audioManager.load()
            } else {
                print("Unrecognized selected segment index.")
            }
            audioManager.setDrumInputVolume(drumLevel)
            audioManager.setGuitarInputVolume(guitarLevel)
        }
    }

    @IBAction func didTapPlayButton(sender:AnyObject?) {
        
        if(audioManager.isPlaying()) {
            audioManager.stopPlaying()
        } else {
            audioManager.startPlaying()
        }
        
        updatePlayButtonText()
    }
    
    @IBAction func didChangeSliderValue(sender:UISlider?) {
        if sender == drumSlider {
            drumLevel = drumSlider.value
            audioManager.setDrumInputVolume(drumLevel)
        } else if sender == guitarSlider {
            guitarLevel = guitarSlider.value
            audioManager.setGuitarInputVolume(guitarLevel)
        }
        
        updateSliderLabels()
    }
    
    func updateSliderLabels() {
        self.drumLabel.text = "Drums: \(Int(drumLevel * 100))%"
        self.guitarLabel.text = "Guitar: \(Int(guitarLevel * 100))%"
    }
    
    func updatePlayButtonText() {
        let buttonText = audioManager.isPlaying() ? "Stop" : "Play"
        UIView.performWithoutAnimation { () -> Void in
            self.playButton.setTitle(buttonText, forState: UIControlState.Normal)
            self.playButton.layoutIfNeeded()
        }
    }

}

