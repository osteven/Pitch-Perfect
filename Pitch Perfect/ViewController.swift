//
//  ViewController.swift
//  Pitch Perfect
//
//  Created by Steven O'Toole on 3/8/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopRecordingButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func recordAudio(sender: UIButton) {
        println("in recordAudio")
        recordingLabel.hidden = false
        stopRecordingButton.hidden = false

    }

    @IBAction func stopRecording(sender: UIButton) {
        recordingLabel.hidden = true
        stopRecordingButton.hidden = true
   }
}

