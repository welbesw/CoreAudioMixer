//
//  FrequencyView.swift
//  CoreAudioMixer
//
//  Created by William Welbes on 3/3/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

import UIKit

class FrequencyView: UIView {

    var barViews:[UIView] = []
    var labelView:UILabel!
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initializeViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initializeViews()
    }
    
    func initializeViews() {
        self.setupBarViews()
        
        //We want to handle the layout of the subviews
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.labelView = UILabel(frame: CGRectZero)
        self.labelView.text = "FFT Frequency Spectrum (Guitar)"
        self.labelView.textColor = UIColor.darkGrayColor()
        self.labelView.backgroundColor = UIColor.clearColor()
        self.labelView.font = UIFont.systemFontOfSize(10.0)
        self.labelView.textAlignment = NSTextAlignment.Center
        self.addSubview(self.labelView)
    }
    
    var frequncyValues: Array<Float> = [] {
        didSet(freqVals) {
            updateBarFrames()
        }
    }

    func setupBarViews() {
        //Create 256 bar views to use for the frequency values
        for _ in 0...255 {
            let view = UIView(frame: CGRectZero)
            view.backgroundColor = self.tintColor
            barViews.append(view)
            self.addSubview(view)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.labelView.frame = CGRectMake(0.0, 0.0, self.frame.size.width, 20.0)
        
        updateBarFrames()
    }
    
    func updateBarFrames() {
        //Layout the bars based on the updated view frame
        let barWidth = self.frame.size.width / CGFloat(barViews.count)
        
        for var i = 0; i < barViews.count; ++i {
            let barView = barViews[i]
            
            var barHeight = CGFloat(0)
            let viewHeight = self.frame.size.height
            if frequncyValues.count > i {
                barHeight = viewHeight * CGFloat(self.frequncyValues[i]);
            }
            
            barView.frame = CGRectMake(CGFloat(i) * barWidth, viewHeight - barHeight, barWidth, barHeight);
        }
    }
}
