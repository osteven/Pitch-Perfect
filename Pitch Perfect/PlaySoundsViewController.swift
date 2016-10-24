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
        guard let recAudio = receivedAudio else { fatalError("Forgot to set receivedAudio in PlaySoundsViewController") }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recAudio.filePathURL as URL)
        } catch let error {
            audioPlayer = nil
            print("error creating AVAudioPlayer: \(error.localizedDescription)")
            return
        }
        if let aPlayer = audioPlayer {
            aPlayer.delegate = self
            aPlayer.enableRate = true
            aPlayer.prepareToPlay()
        } else {
            print("unknown error creating Audio Player")
            return
        }
        do {
            audioFile = try AVAudioFile(forReading: recAudio.filePathURL as URL)
        } catch let error {
            print("error loading AVAudioFile: \(error.localizedDescription)")
            audioFile = nil
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manageButtons()
    }


    func manageButtons() {
        var notPlaying = ((audioPlayer == nil) || !audioPlayer!.isPlaying)
        if (notPlaying) { notPlaying = !audioEngineIsPlaying }

        stopPlayingButton.isHidden = notPlaying
        slowPlayButton.isEnabled = notPlaying
        quickPlayButton.isEnabled = notPlaying
        chipmunkPlayButton.isEnabled = notPlaying
        darthVaderPlayButton.isEnabled = notPlaying
        reverbPlayButton.isEnabled = notPlaying
        echoPlayButton.isEnabled = notPlaying
    }


    // MARK: -
    // MARK: Audio Play Utilities
    func playSound(_ rate: Float) {
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

    func playAudioWithVariablePitch(_ pitch: Float) {
        func pitchBlock() -> AVAudioUnit {
            let changePitchEffect = AVAudioUnitTimePitch()
            changePitchEffect.pitch = pitch
            return changePitchEffect
        }
        audioEngineCommon(pitchBlock)
    }

    /* pass in a closure that creates an AVAudioUnit effectNode with the desired effect
        everything else is common boilerplate
        Some of the boilerplate is from:
        http://stackoverflow.com/questions/24443863/trouble-hooking-up-avaudiouniteffect-with-avaudioengine
        Closure ideas from: http://hondrouthoughts.blogspot.com/2014/09/more-avaudioplayernode-with-swift-and.html
    */
    func audioEngineCommon(_ effectBlock: EffectBlock) {
        guard let audioFile = self.audioFile else { print("audioFile is nil in audioEngineCommon"); return }
        if (nil != audioPlayer) { audioPlayer!.stop() }
        resetAudioEngine()

        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)

        let effectNode = effectBlock()

        audioEngine.attach(effectNode)

        audioEngine.connect(audioPlayerNode, to: effectNode, format: nil)
        audioEngine.connect(effectNode, to: audioEngine.outputNode, format: nil)

        audioEngineIsPlaying = true
        audioPlayerNode.scheduleFile(audioFile, at: nil, completionHandler: { () -> Void in
            self.audioEngineIsPlaying = false
            self.audioEngineIsPlaying = false
            guard let lastRenderTime = audioPlayerNode.lastRenderTime,
                let playerTime = audioPlayerNode.playerTime(forNodeTime: lastRenderTime) else {
                DispatchQueue.main.async { self.manageButtons() }
                return
            }

            /* Dispatch it on main queue to work around the bug in AVAudioPlayerNode.scheduleFile that delays
            the update for 5 seconds.  This workaround makes the update happen too quickly (especially
            the echo effect).  I tried inserting a delay, but that screws up the audio (again especially
            the echo effect).
            http://discussions.udacity.com/t/avaudioplayernode-schedulefile-with-a-completionhandler/12872/2
            */
            let remainingDuration = Double(audioFile.length) - Double(playerTime.sampleTime)
            let delayInSecs: Double =  Double(NSEC_PER_SEC) * (remainingDuration / audioFile.processingFormat.sampleRate)
            let delayTime = DispatchTime.now() + Double(Int64(delayInSecs)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime, execute: { self.manageButtons() })
        })

        do {
            try audioEngine.start()
        } catch let error {
            print("error starting up Audio Engine: \(error.localizedDescription)")
            return
        }
        audioPlayerNode.play()
        manageButtons()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        manageButtons()
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


    /* reverb based on: https://books.google.com/books?id=5baVBQAAQBAJ&pg=PA707&lpg=PA707&dq=AVAudioUnitReverb&source=bl&ots=3X2xSCaIS9&sig=p2ipP-sRSFrvXRbWKAgCSmCLhmI&hl=en&sa=X&ei=Ph4CVdCqLcSlyATNmYKYAg&ved=0CCMQ6AEwATgK#v=onepage&q=AVAudioUnitReverb&f=false
    */
    @IBAction func playSoundReverb() {
        func reverbBlock() -> AVAudioUnit {
            let reverbEffect = AVAudioUnitReverb()
            reverbEffect.loadFactoryPreset(.cathedral)
            reverbEffect.wetDryMix = 40
            return reverbEffect
        }
        audioEngineCommon(reverbBlock)
    }
    @IBAction func playSoundEcho() {
        func echoBlock() -> AVAudioUnit {
            let echoEffect = AVAudioUnitDelay()
            echoEffect.wetDryMix = 50
            return echoEffect
        }
        audioEngineCommon(echoBlock)
    }
}



/*




*/
