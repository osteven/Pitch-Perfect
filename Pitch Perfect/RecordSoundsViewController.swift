//
//  RecordSoundsViewController.swift
//  Pitch Perfect
//
//  Created by Steven O'Toole on 3/8/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {


    // MARK: -
    // MARK: Properties
    var audioRecorder: AVAudioRecorder? = nil
    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    let wavFileNameFormatter = NSDateFormatter()
    let audioSession = AVAudioSession.sharedInstance()
    var recordedAudio: RecordedAudio? = nil
    var recordingIsPaused = false


    // MARK: -
    // MARK: Outlets
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopRecordingButton: UIButton!
    @IBOutlet weak var stopRecordingLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var pauseRecordingButton: UIButton!
    @IBOutlet weak var resumeRecordingButton: UIButton!




    // MARK: -
    // MARK: Loading and UI
    override func viewDidLoad() {
        super.viewDidLoad()
        wavFileNameFormatter.dateFormat = "ddMMyyyy-HHmmss"
    }

    override func viewWillAppear(animated: Bool) {
        manageButtonsAndLabels()
        managePauseResumeUI()
    }

    func manageButtonsAndLabels() {
        let recording = (audioRecorder != nil) ? audioRecorder!.recording : false
        recordingLabel.text = recording ? "Recording in progress" : "Tap to record"
        stopRecordingButton.hidden = !recording
        stopRecordingLabel.hidden = !recording
        recordButton.enabled = !recording
        pauseRecordingButton.hidden = !recording
        resumeRecordingButton.hidden = !recording
        stopRecordingLabel.text = "Tap to finish or pause"
    }

    func managePauseResumeUI() {
        pauseRecordingButton.enabled = !recordingIsPaused
        resumeRecordingButton.enabled = recordingIsPaused
        stopRecordingLabel.text = recordingIsPaused ? "Tap arrow to resume" : "Tap to finish or pause"
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "stopRecording" {
            let playSoundsVC = segue.destinationViewController as PlaySoundsViewController
            if let recAudio = sender as? RecordedAudio {
                playSoundsVC.receivedAudio = recAudio
            }
        }
    }


    // MARK: -
    // MARK: Audio Recording Utility
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        if !flag {
            println("Recording was not successful")
            manageButtonsAndLabels()
            return
        }
        if var title = recorder.url.lastPathComponent {
            recordedAudio = RecordedAudio(title: title, andURL: recorder.url)
            self.performSegueWithIdentifier("stopRecording", sender: recordedAudio)
        }
        manageButtonsAndLabels()
    }


    // MARK: -
    // MARK: Actions

    @IBAction func recordAudio() {
        let wavFileRecordingName = wavFileNameFormatter.stringFromDate(NSDate())
        let pathArray = [dirPath, wavFileRecordingName]
        let filePathURL = NSURL.fileURLWithPathComponents(pathArray)
        var error: NSError?
        audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, error: &error)
        if let e = error {
            println("error setting up Audio Session: \(e.localizedDescription)")
        } else {
            audioRecorder = AVAudioRecorder(URL: filePathURL, settings: nil, error: &error)
            if let aRecorder = audioRecorder {
                aRecorder.delegate = self
                aRecorder.prepareToRecord()
                aRecorder.record()
            } else if let e = error {
                println("error setting up Audio Recorder: \(e.localizedDescription)")
            } else {
                println("unknown error setting up Audio Recorder")
            }
        }
        manageButtonsAndLabels()
    }

    @IBAction func stopRecording() {
        if var ar = audioRecorder { ar.stop() }
        audioSession.setActive(false, error: nil)
        manageButtonsAndLabels()
    }


    @IBAction func pauseRecording() {
        if var ar = audioRecorder {
            ar.pause()
            recordingIsPaused = true
        }
        managePauseResumeUI()
    }

    @IBAction func resumeRecording() {
        if var ar = audioRecorder { ar.record() }
        recordingIsPaused = false
        managePauseResumeUI()
   }
}

