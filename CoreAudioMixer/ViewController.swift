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
    
    var drumLevel:Float = 1.0
    var guitarLevel:Float = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load the core audio manager and initialize the graph
        
        CoreAudioManager.sharedInstance().loadAudioFiles()
        CoreAudioManager.sharedInstance().initializeAUGraph()
        
        drumSlider.value = drumLevel
        guitarSlider.value = guitarLevel
        updateSliderLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didTapPlayButton(sender:AnyObject?) {
        
        let manager = CoreAudioManager.sharedInstance()
        
        if(manager.isPlaying) {
            manager.stopPlaying()
        } else {
            manager.startPlaying()
        }
        
        updatePlayButtonText()
    }
    
    @IBAction func didChangeSliderValue(sender:UISlider?) {
        if sender == drumSlider {
            drumLevel = drumSlider.value
            CoreAudioManager.sharedInstance().setDrumInputVolume(drumLevel)
        } else if sender == guitarSlider {
            guitarLevel = guitarSlider.value
            CoreAudioManager.sharedInstance().setGuitarInputVolume(guitarLevel)
        }
        
        updateSliderLabels()
    }
    
    func updateSliderLabels() {
        self.drumLabel.text = "Drums: \(Int(drumLevel * 100))%"
        self.guitarLabel.text = "Guitar: \(Int(guitarLevel * 100))%"
    }
    
    func updatePlayButtonText() {
        let buttonText = CoreAudioManager.sharedInstance().isPlaying ? "Stop" : "Start"
        UIView.performWithoutAnimation { () -> Void in
            self.playButton.setTitle(buttonText, forState: UIControlState.Normal)
            self.playButton.layoutIfNeeded()
        }
    }

}

