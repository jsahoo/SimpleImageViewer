//
//  Media.swift
//  SimpleImageViewer
//
//  Created by Jonathan Sahoo on 1/13/21.
//  Copyright © 2021 Jonathan Sahoo. All rights reserved.
//

import UIKit

public enum Media {
    case image(UIImage)
    case imageFromRemoteURL(URL)
    case imageFromData(Data)
    case imageFromCustom((() -> UIImage))
    case videoFromLocalURL(URL)
    case videoFromCustom((() -> URL))
}
