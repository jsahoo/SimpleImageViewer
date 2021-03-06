import UIKit
import SDWebImage
import AVKit

// TODO: Needs a play button overlay when media is video

public final class FullScreenMediaViewController: UIViewController {

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var overlayViews: [UIView]!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    private var avPlayer = AVQueuePlayer()
    private var avPlayerLayer: AVPlayerLayer?
    private var avPlayerLooper: AVPlayerLooper?

    private let thresholdVelocity: CGFloat = 500 // The speed of swipe needs to be at least this amount of pixels per second for the swipe to finish dismissal.
    private let swipeToDismissRecognizer = UIPanGestureRecognizer()

    private var media: Media?
    private var swipingToDismiss = false
    private var swipeToDismissTransition: GallerySwipeToDismissTransition?

    private var overlayAlpha: CGFloat = 1 {
        didSet { overlayViews.forEach { $0.alpha = overlayAlpha } }
    }

    var controllerIsSwipingToDismiss: ((_ distanceToEdge: CGFloat) -> Void)?
    var controllerDidDismissViaSwipe: (() -> Void)?
    
    public init(media: Media) {
        self.media = media
        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        switch media {
        case .image(let image):
            imageView.image = image
        case .imageFromRemoteURL(let url):
            imageView.sd_setImage(with: url) { [weak self] (image, _, _, _) in
                self?.imageView.image = image
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }
        case .imageFromData(let data):
            imageView.image = UIImage(data: data)
        case .imageFromCustom(let closure):
            imageView.image = closure()
        case .videoFromLocalURL(let url):
            setupVideo(url: url)
        case .videoFromCustom(let closure):
            setupVideo(url: closure())
        default:
            break
        }
        
        setupScrollView()
        setupGestureRecognizers()

        // Disable scrolling when fully zoomed out (which we are by default) to prevent scroll view from intercepting swipe to dismiss. Re-enable it when zoomed in (below) to allow panning the zoomed in image
        scrollView.isScrollEnabled = false
    }

    private func setupVideo(url: URL) {
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.frame = UIScreen.main.bounds
        imageView.layer.addSublayer(avPlayerLayer!)
        avPlayerLayer?.videoGravity = .resizeAspect
        avPlayerLooper = AVPlayerLooper(player: avPlayer, templateItem: AVPlayerItem(url: url))
        avPlayer.volume = 0 // intentionally disabling for now until we can get a UI toggle
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        overlayAlpha = PagingViewController.overlayIsHidden ? 0 : 1
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Play video (if there is one) automatically
        avPlayer.play()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Reset zoom when view disappears
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        // Pause video (if there is one)
        avPlayer.pause()
    }

    deinit {
        self.scrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }
}

private extension FullScreenMediaViewController {
    func setupScrollView() {
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    func setupGestureRecognizers() {
        let doubleTapGestureRecognizer = UITapGestureRecognizer()
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.addTarget(self, action: #selector(handleDoubleTap))
        view.addGestureRecognizer(doubleTapGestureRecognizer)

        let singleTapGestureRecognizer = UITapGestureRecognizer()
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.addTarget(self, action: #selector(handleSingleTap))
        view.addGestureRecognizer(singleTapGestureRecognizer)
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)

        swipeToDismissRecognizer.addTarget(self, action: #selector(handleSwipe))
        swipeToDismissRecognizer.delegate = self
        view.addGestureRecognizer(swipeToDismissRecognizer)
        swipeToDismissRecognizer.require(toFail: doubleTapGestureRecognizer)
    }
    
    @IBAction func closeButtonPressed() {
        dismiss(animated: true)
    }

    @objc func handleSingleTap(recognizer: UITapGestureRecognizer) {
        // If we're zoomed in, zoom out. Otherwise, toggle the overlay on/off
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            toggleOverlay(visible: overlayAlpha == 0)
        }

        // Toggle video play/pause
        if avPlayer.rate != 0 {
            avPlayer.pause()
        } else {
            avPlayer.play()
        }
    }

    private func toggleOverlay(visible: Bool) {
        let targetAlpha: CGFloat = visible ? 1 : 0
        UIView.animate(withDuration: 0.15, animations: { [weak self] in
            self?.overlayAlpha = targetAlpha
        })
        PagingViewController.overlayIsHidden = targetAlpha == 0
    }
    
    @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
            var zoomRect = CGRect.zero
            zoomRect.size.height = imageView.frame.size.height / scale
            zoomRect.size.width  = imageView.frame.size.width  / scale
            let newCenter = scrollView.convert(center, from: imageView)
            zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
            zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
            return zoomRect
        }

        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            toggleOverlay(visible: false)
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        }
    }
}

extension FullScreenMediaViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let image = imageView.image else { return }
        let imageViewSize = Utilities.aspectFitRect(forSize: image.size, insideRect: imageView.frame)
        let verticalInsets = -(scrollView.contentSize.height - max(imageViewSize.height, scrollView.bounds.height)) / 2
        let horizontalInsets = -(scrollView.contentSize.width - max(imageViewSize.width, scrollView.bounds.width)) / 2
        scrollView.contentInset = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)
    }

    // Always hide the overlay before zooming
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        toggleOverlay(visible: false)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // Hide overlay & enable scrolling after zooming in; show overlay & disable scrolling after zooming out
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            toggleOverlay(visible: false)
            scrollView.isScrollEnabled = true
        } else {
            toggleOverlay(visible: true)
            scrollView.isScrollEnabled = false
        }
    }
}

// MARK: - Swipe To Dismiss

extension FullScreenMediaViewController: UIGestureRecognizerDelegate {

    // We only want the swipeToDismissRecognizer to handle vertical swipes. Horizontal swipes should be disregarded so that the UIPageViewController can handle it for paging
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == swipeToDismissRecognizer else { return false }
        let velocity = swipeToDismissRecognizer.velocity(in: swipeToDismissRecognizer.view)
        return abs(velocity.y) > abs(velocity.x)
    }

    @objc func handleSwipe(_ recognizer: UIPanGestureRecognizer) {
        /// A deliberate UX decision...you have to zoom back in to scale 1 to be able to swipe to dismiss. It is difficult for the user to swipe to dismiss from images larger then screen bounds because almost all the time it's not swiping to dismiss but instead panning a zoomed in picture on the canvas.
        guard scrollView.zoomScale == scrollView.minimumZoomScale else { return }

        let currentVelocity = recognizer.velocity(in: self.view)
        let currentTouchPoint = recognizer.translation(in: view)

        swipingToDismiss = true

        switch recognizer.state {
        case .began:
            swipeToDismissTransition = GallerySwipeToDismissTransition(scrollView: self.scrollView)
        case .changed:
            swipeToDismissTransition?.updateInteractiveTransition(verticalOffset: -currentTouchPoint.y)
        case .ended:
            self.handleSwipeToDismissEnded(finalVelocity: currentVelocity, finalTouchPoint: currentTouchPoint)
        default:
            break
        }
    }

    func handleSwipeToDismissEnded(finalVelocity velocity: CGPoint, finalTouchPoint touchPoint: CGPoint) {

        let swipeToDismissCompletionBlock = { [weak self] in
            UIApplication.applicationWindow?.windowLevel = UIWindow.Level.normal
            self?.swipingToDismiss = false
            self?.controllerDidDismissViaSwipe?()
        }

        switch velocity {
        // Swiping Up
        case _ where velocity.y < -thresholdVelocity:
            swipeToDismissTransition?.finishInteractiveTransition(touchPoint: touchPoint.y,
                                                                  targetOffset: (view.bounds.height / 2) + (imageView.bounds.height / 2),
                                                                  escapeVelocity: velocity.y,
                                                                  completion: swipeToDismissCompletionBlock)
        // Swiping Down
        case _ where thresholdVelocity < velocity.y:
            swipeToDismissTransition?.finishInteractiveTransition(touchPoint: touchPoint.y,
                                                                  targetOffset: -(view.bounds.height / 2) - (imageView.bounds.height / 2),
                                                                  escapeVelocity: velocity.y,
                                                                  completion: swipeToDismissCompletionBlock)
        // If none of the above select cases, we cancel.
        default:
            swipeToDismissTransition?.cancelTransition() { [weak self] in
                self?.swipingToDismiss = false
            }
        }
    }

    // Reports the continuous progress of Swipe To Dismiss to the Paging View Controller
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard swipingToDismiss, keyPath == "contentOffset" else { return }
        let distanceToEdge: CGFloat = (scrollView.bounds.height / 2) + (imageView.bounds.height / 2)
        let percentDistance: CGFloat = abs(scrollView.contentOffset.y / distanceToEdge)
        controllerIsSwipingToDismiss?(percentDistance)
    }
}

extension UIApplication {
    static var applicationWindow: UIWindow? {
        return (UIApplication.shared.delegate?.window?.flatMap { $0 })
    }
}

