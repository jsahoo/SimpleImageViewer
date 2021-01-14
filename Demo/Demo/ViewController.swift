//
//  ViewController.swift
//  Demo
//
//  Created by Jonathan Sahoo on 5/12/20.
//  Copyright © 2020 Jonathan Sahoo. All rights reserved.
//

import UIKit
import SimpleImageViewer
import SDWebImage

class ViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    private let media: [Media] = [
        .image(UIImage(named: "1")!),
        .image(UIImage(named: "2")!),
        .image(UIImage(named: "3")!),
        .image(UIImage(named: "4")!),
        .image(UIImage(named: "5")!),
        .image(UIImage(named: "6")!),
        .imageFromRemoteURL(URL(string: "https://picsum.photos/1500?image=1084")!),
        .imageFromRemoteURL(URL(string: "https://picsum.photos/1500?image=1083")!),
        .imageFromRemoteURL(URL(string: "https://picsum.photos/1500?image=1082")!),
        .imageFromRemoteURL(URL(string: "https://picsum.photos/1500?image=1081")!)
    ]
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell

        switch media[indexPath.row] {
        case .image(let image):
            cell.imageView.image = image
        case .imageFromRemoteURL(let url):
            cell.imageView.sd_setImage(with: url, completed: nil)
        case .imageFromData(let data):
            cell.imageView.image = UIImage(data: data)
        case .imageFromCustom(let closure):
            cell.imageView.image = closure()
        case .videoFromLocalURL(let url):
            cell.imageView.image = nil
        case .videoFromCustom(let closure):
            cell.imageView.image = nil
        }

        cell.imageView.contentMode = .scaleAspectFill
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        present(PagingViewController(images: media, initialIndex: indexPath.row), animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.frame.width / 3 - 8
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

