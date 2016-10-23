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
    let filePathURL: URL

    init(title: String, andURL URL: Foundation.URL) {
        self.title = title
        self.filePathURL = URL
    }
}
