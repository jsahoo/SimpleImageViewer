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

    fileprivate let images = [Image(image: UIImage(named: "1")),
                              Image(image: UIImage(named: "2")),
                              Image(image: UIImage(named: "3")),
                              Image(image: UIImage(named: "4")),
                              Image(image: UIImage(named: "5")),
                              Image(image: UIImage(named: "6")),
                              Image(urlString: "https://picsum.photos/1500?image=1084"),
                              Image(urlString: "https://picsum.photos/1500?image=1083"),
                              Image(urlString: "https://picsum.photos/1500?image=1082"),
                              Image(urlString: "https://picsum.photos/1500?image=1081")].compactMap({$0})
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        if let image = images[indexPath.row].image {
            cell.imageView.image = image
        } else if let url = images[indexPath.row].url {
            cell.imageView.sd_setImage(with: url, completed: nil)
        } else {
            cell.imageView.image = nil
        }
        cell.imageView.contentMode = .scaleAspectFill
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        present(PagingViewController(images: images.compactMap({$0}), initialIndex: indexPath.row), animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.frame.width / 3 - 8
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

