//
//  PagingViewController.swift
//  SimpleImageViewer
//
//  Created by Jonathan Sahoo on 7/31/18.
//  Copyright © 2018 Jonathan Sahoo. All rights reserved.
//

import UIKit

public class PagingViewController: UIPageViewController {

    static var overlayIsHidden = false

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    private var pages = [UIViewController]()
    private var initialIndex: Int?

    public convenience init(media: [Media], initialIndex: Int? = nil) {
        self.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [UIPageViewController.OptionsKey.interPageSpacing : 20])

        self.initialIndex = initialIndex

        media.forEach {
            let controller = FullScreenMediaViewController(media: $0)
            controller.controllerIsSwipingToDismiss = { [weak self] distanceToEdge in
                self?.view.alpha = 1 - distanceToEdge
            }
            controller.controllerDidDismissViaSwipe = { [weak self] in
                self?.dismiss(animated: false, completion: nil)
            }
            pages.append(controller)
        }

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        modalPresentationCapturesStatusBarAppearance = true
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = pages.count > 1 ? self : nil // We disable horizontal swiping between pages (by setting the datasource to nil) when there's only one image

        if let initialIndex = initialIndex, initialIndex < pages.count {
            setViewControllers([pages[initialIndex]], direction: .forward, animated: true, completion: nil)
        } else if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }

        view.backgroundColor = .black // Have to set the background to black when modalPresentationStyle = .overFullScreen to prevent seeing the presenting view controller when swiping between pages
    }
}

extension PagingViewController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let previousIndex = index - 1
        guard previousIndex >= 0 else { return pages.last }
        guard pages.count > previousIndex else { return nil }
        return pages[previousIndex]
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let nextIndex = index + 1
        guard nextIndex < pages.count else { return pages.first }
        guard pages.count > nextIndex else { return nil }
        return pages[nextIndex]
    }
}
