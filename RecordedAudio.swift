//
//  RecordedAudio.swift
//  Pitch Perfect
//
//  Created by Steven O'Toole on 3/10/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation


class RecordedAudio {
    let title: String
    let filePathURL: NSURL

    init(title: String, andURL URL: NSURL) {
        self.title = title
        self.filePathURL = URL
    }
}