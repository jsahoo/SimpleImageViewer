//
//  Image.swift
//  SimpleImageViewer
//
//  Created by Jonathan Sahoo on 8/6/18.
//

import Foundation
import SDWebImage

public struct Image {
    public private(set) var url: URL?
    public private(set) var image: UIImage?

    public init?(urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else { return nil }
        self.url = url
    }

    public init?(url: URL?) {
        guard let url = url else { return nil }
        self.url = url
    }

    public init?(image: UIImage?) {
        guard let image = image else { return nil }
        self.image = image
    }
}
