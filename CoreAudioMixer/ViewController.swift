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
    
    @IBOutlet var frequencyView:FrequencyView!
    
    var drumLevel:Float = 1.0
    var guitarLevel:Float = 1.0
    
    var audioManager:AudioManager!
    
    var timer:Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the core audio manager and initialize the graph
        
        //Start with the CoreAudioManager as the default
        audioManager = CoreAudioManager()
        audioManager.load()
        
        drumSlider.value = drumLevel
        guitarSlider.value = guitarLevel
        updateSliderLabels()
        
        timer = Timer(timeInterval: 0.01, target: self, selector: #selector(ViewController.timerTick(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func timerTick(_ sender:Timer?) {
        if audioManager.isPlaying() {
            //Get the frequency data from the audio manager and show on horizontal bar graph
            var size:UInt32 = 0
            let frequencyData = audioManager.guitarFrequencyData(ofLength: &size)
            //let frequencyData = audioManager.drumsFrequencyDataOfLength(&size)
            let frequencyValuesArray = Array<Float32>(UnsafeBufferPointer(start: UnsafePointer(frequencyData), count: Int(size)))
            
            //Sanity check for expected 256 length
            if frequencyValuesArray.count == 256 {
                frequencyView.frequncyValues = frequencyValuesArray
            }
        }
    }
    
    @IBAction func didChangeSegmentedControlValue(_ sender:UISegmentedControl?) {
        if sender == segmentedControl {
            //Stop any audio before changing managers
            audioManager.stopPlaying()
            updatePlayButtonText()
            
            let index = segmentedControl.selectedSegmentIndex
            if index == 0 {
                audioManager = CoreAudioManager()
                audioManager.load()
                frequencyView.alpha = 1.0
            } else if (index == 1) {
                audioManager = AudioEngineManager()
                audioManager.load()
                self.frequencyView.alpha = 0.0
            } else {
                print("Unrecognized selected segment index.")
            }
            audioManager.setDrumInputVolume(drumLevel)
            audioManager.setGuitarInputVolume(guitarLevel)
        }
    }

    @IBAction func didTapPlayButton(_ sender:AnyObject?) {
        
        if(audioManager.isPlaying()) {
            audioManager.stopPlaying()
        } else {
            audioManager.startPlaying()
        }
        
        updatePlayButtonText()
    }
    
    @IBAction func didChangeSliderValue(_ sender:UISlider?) {
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
            self.playButton.setTitle(buttonText, for: UIControlState())
            self.playButton.layoutIfNeeded()
        }
    }

}

