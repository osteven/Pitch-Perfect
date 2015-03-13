//
//  PlaySoundsViewController.swift
//  Pitch Perfect
//
//  Created by Steven O'Toole on 3/9/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit
import AVFoundation


class PlaySoundsViewController: UIViewController, AVAudioPlayerDelegate {


    // MARK: -
    // MARK: Properties
    var audioPlayer: AVAudioPlayer? = nil
    var receivedAudio: RecordedAudio? = nil

    let audioEngine: AVAudioEngine = AVAudioEngine()
    var audioFile: AVAudioFile? = nil
    var audioEngineIsPlaying = false
    var audioDuration: NSTimeInterval = 0.0
    var isEchoEffect = false
    var audioBegin: NSDate? = nil

    // MARK: -
    // MARK: Outlets
    @IBOutlet weak var stopPlayingButton: UIButton!
    @IBOutlet weak var slowPlayButton: UIButton!
    @IBOutlet weak var quickPlayButton: UIButton!
    @IBOutlet weak var chipmunkPlayButton: UIButton!
    @IBOutlet weak var darthVaderPlayButton: UIButton!
    @IBOutlet weak var reverbPlayButton: UIButton!
    @IBOutlet weak var echoPlayButton: UIButton!


    // MARK: -
    // MARK: Loading and UI
    override func viewDidLoad() {
        super.viewDidLoad()

        if let recAudio = receivedAudio {
            var error: NSError?
            audioPlayer = AVAudioPlayer(contentsOfURL: recAudio.filePathURL, error: &error)
            if let aPlayer = audioPlayer {
                audioDuration = aPlayer.duration
                println("duration=\(audioDuration)")
                aPlayer.delegate = self
                aPlayer.enableRate = true
                aPlayer.prepareToPlay()
            } else if let e = error {
                println("error loading receivedAudio URL: \(e.localizedDescription)")
                return
            } else {
                println("unknown error creating Audio Player")
                return
            }
            audioFile = AVAudioFile(forReading: recAudio.filePathURL, error: &error)
            if nil != error { println("error loading AVAudioFile: \(error!.localizedDescription)") }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        isEchoEffect = false
        manageButtons()
    }


    func manageButtons() {
        var notPlaying = ((audioPlayer == nil) || !audioPlayer!.playing)
        if (notPlaying) { notPlaying = !audioEngineIsPlaying }

        stopPlayingButton.hidden = notPlaying
        slowPlayButton.enabled = notPlaying
        quickPlayButton.enabled = notPlaying
        chipmunkPlayButton.enabled = notPlaying
        darthVaderPlayButton.enabled = notPlaying
        reverbPlayButton.enabled = notPlaying
        echoPlayButton.enabled = notPlaying

        if (self.audioBegin != nil) {
            let audioEnd = NSDate()
            let timeInterval: Double = audioEnd.timeIntervalSinceDate(self.audioBegin!);
            println("   buttons=\(timeInterval)")
        }
    }


    // MARK: -
    // MARK: Audio Play Utilities
    func playSound(rate: Float) {
        resetAudioEngine()
        if nil != audioPlayer {
            audioPlayer!.rate = rate
            audioPlayer!.currentTime = 0.0
            audioPlayer!.play()
        }
        manageButtons()
    }

    func resetAudioEngine() {
        audioEngine.stop()
        audioEngine.reset()
        audioEngineIsPlaying = false
    }



    typealias EffectBlock = () -> AVAudioUnit

    func playAudioWithVariablePitch(pitch: Float) {
        func pitchBlock() -> AVAudioUnit {
            let changePitchEffect = AVAudioUnitTimePitch()
            changePitchEffect.pitch = pitch
            return changePitchEffect
        }
        audioEngineCommon(pitchBlock)
    }

    // pass in a closure that creates an AVAudioUnit effectNode with the desired effect
    // everything else is common boilerplate
    func audioEngineCommon(effectBlock: EffectBlock) {
        if (nil != audioPlayer) { audioPlayer!.stop() }
        resetAudioEngine()

        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)

        let effectNode = effectBlock()

        audioEngine.attachNode(effectNode)

        audioEngine.connect(audioPlayerNode, to: effectNode, format: nil)
        audioEngine.connect(effectNode, to: audioEngine.outputNode, format: nil)

        audioEngineIsPlaying = true
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: { () -> Void in
            let audioEnd = NSDate()
            let timeInterval: Double = audioEnd.timeIntervalSinceDate(self.audioBegin!);
            println("   actual=\(timeInterval)")
            self.audioEngineIsPlaying = false

            let delaySecs = self.isEchoEffect ? self.audioDuration * 0.5 : 1.0

            self.delay(delaySecs, self.manageButtons)

            //         dispatch_async(dispatch_get_main_queue()) { self.manageButtons() }
        })
        audioEngine.startAndReturnError(nil)

        audioBegin = NSDate()
        audioPlayerNode.play()
        manageButtons()
    }

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        manageButtons()
    }



    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }


    // MARK: -
    // MARK: Actions

    @IBAction func playSoundSlowly() { playSound(0.5) }
    @IBAction func playSoundQuickly() { playSound(1.5) }
    
    @IBAction func stopPlaying() {
        if audioPlayer != nil {
            audioPlayer!.stop()
        }
        resetAudioEngine()
        manageButtons()
    }

    @IBAction func playSoundChipmunk() { playAudioWithVariablePitch(1000) }
    @IBAction func playSoundDarthVader() { playAudioWithVariablePitch(-1000) }

    @IBAction func playSoundReverb() {
        func reverbBlock() -> AVAudioUnit {
            let reverbEffect = AVAudioUnitReverb()
            reverbEffect.loadFactoryPreset(.Cathedral)
            reverbEffect.wetDryMix = 40
            return reverbEffect
        }
        audioEngineCommon(reverbBlock)
    }
    @IBAction func playSoundEcho() {
        func echoBlock() -> AVAudioUnit {
            isEchoEffect = true
            let echoEffect = AVAudioUnitDelay()
            echoEffect.wetDryMix = 50
            return echoEffect
        }
        audioEngineCommon(echoBlock)
    }
}
