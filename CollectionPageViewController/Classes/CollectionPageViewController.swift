//
//  CollectionPageViewController.swift
//  CollectionPageViewController
//
//  Created by Ahmed Khalaf on 10/4/19.
//

import UIKit

public protocol CollectionPageViewControllerDataSource: AnyObject {
    func numberOfViewControllers(in collectionPageViewController: CollectionPageViewController) -> Int
    func collectionPageViewController(_ collectionPageViewController: CollectionPageViewController, viewControllerAt index: Int) -> UIViewController
}

open class CollectionPageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public enum NavigationOrientation {
        case horizontal, vertical
        
        internal var collectionViewScrollDirection: UICollectionView.ScrollDirection {
            switch self {
                case .horizontal: return .horizontal
                case .vertical:   return .vertical
            }
        }
        
        internal init(collectionViewScrollDirection: UICollectionView.ScrollDirection) {
            switch collectionViewScrollDirection {
                case .horizontal: self = .horizontal
                case .vertical: self = .vertical
            @unknown default:
                self = .horizontal
            }
        }
    }
    
    open var navigationOrientation: NavigationOrientation {
        set {
            let scrollRate: CGFloat
            switch navigationOrientation {
            case .horizontal:
                scrollRate = collectionView.contentOffset.x / collectionView.contentSize.width
            case .vertical:
                scrollRate = collectionView.contentOffset.y / collectionView.contentSize.height
            }
            collectionView.addSnapshot()
            collectionView.flowLayout?.scrollDirection = newValue.collectionViewScrollDirection
            collectionView.flowLayout?.invalidateLayout()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(scrollRate)) {
                switch newValue {
                case .horizontal:
                    self.collectionView.contentOffset.x = self.collectionView.contentSize.width * scrollRate
                case .vertical:
                    self.collectionView.contentOffset.y = self.collectionView.contentSize.height * scrollRate
                }
                self.collectionView.removeSnapshot()
            }
        }
        
        get {
            return NavigationOrientation(collectionViewScrollDirection: collectionView.flowLayout?.scrollDirection ?? .horizontal)
        }
    }
    open var index: Int {
        get {
            switch navigationOrientation {
            case .horizontal: return Int((collectionView.contentOffset.x + collectionView.bounds.width / 2) / collectionView.bounds.width)
            case .vertical: return Int((collectionView.contentOffset.y + collectionView.bounds.height / 2) / collectionView.bounds.height)
            }
        }
        
        set {
            guard (0..<count).contains(newValue
            ), newValue != index, let snapshotImage = collectionView.makeSnapshotImage() else { return }
            
            if let nearestIndex = scrollIfNeededWithoutAnimation(to: newValue) {
                collectionView.impose(image: snapshotImage, onCellAt: nearestIndex)
            }
            scrollAnimated(to: newValue) {
                self.collectionView.removeImposedSnapshot()
            }
        }
    }
    open weak var dataSource: CollectionPageViewControllerDataSource?
    
    private let collectionViewCellReuseIdentifier = "cell"
    private lazy var collectionView: CollectionView = {
        let cvLayout = UICollectionViewFlowLayout()
        let cv = CollectionView(frame: .zero, collectionViewLayout: cvLayout)
        cv.isPagingEnabled = true
        cv.dataSource = self
        cv.delegate = self
        cv.register(CollectionViewCell.self, forCellWithReuseIdentifier: collectionViewCellReuseIdentifier)
        return cv
    }()
    
    private func addCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            view.topAnchor.constraint(equalTo: collectionView.topAnchor),
            view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])
    }
    
    private func removeViewController(from cell: UICollectionViewCell) {
        if let viewController = children.first(where: { $0.view === cell.contentView.subviews.first }) {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
    }
    
    private var count: Int {
        switch navigationOrientation {
            case .horizontal: return Int(collectionView.contentSize.width / collectionView.bounds.width)
            case .vertical: return Int(collectionView.contentSize.height / collectionView.bounds.height)
        }
    }
    
    @discardableResult
    private func scrollIfNeededWithoutAnimation(to index: Int) -> Int? {
        guard abs(index - self.index) > 1 else { return nil }
        let index = index > self.index ? index - 1 : index + 1
        collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: navigationOrientation == .horizontal ? .centeredHorizontally : .centeredVertically, animated: false)
        return index
    }
    
    private func scrollAnimated(to index: Int, completionHandler: (() -> Void)? = nil) {
        collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: navigationOrientation == .horizontal ? .centeredHorizontally : .centeredVertically, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completionHandler?()
        }
    }
    
    private func setCollectionViewContentOffsetWithoutAnimation(for index: Int) {
        switch navigationOrientation {
            case .horizontal:
                collectionView.contentOffset.x = CGFloat(index) * collectionView.bounds.width
            case .vertical:
                collectionView.contentOffset.y = CGFloat(index) * collectionView.bounds.height
        }
    }
    
    // MARK: - Overrides
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        addCollectionView()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        let index = self.index
        collectionView.addSnapshot()
        coordinator.animate(alongsideTransition: { (_) in
            self.collectionView.flowLayout?.invalidateLayout()
            self.setCollectionViewContentOffsetWithoutAnimation(for: index)
            NotificationCenter.default.post(name: hideCellNotification, object: nil, userInfo: [showHideCellNotificationIndexParameterName: index])
            UIView.performWithoutAnimation {
                self.view.layoutIfNeeded()
            }
        }) { (_) in
            self.collectionView.removeSnapshot()
            NotificationCenter.default.post(name: showCellNotification, object: nil, userInfo: [showHideCellNotificationIndexParameterName: index])
        }
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - UICollectionViewDataSource
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfViewControllers(in: self) ?? 0
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellReuseIdentifier, for: indexPath) as! CollectionViewCell
        cell.index = indexPath.row
        cell.willPrepareForReuse = { [weak self] in
            guard let self = self else { return }
            self.removeViewController(from: cell)
        }
        if let dataSource = dataSource {
            let viewController = dataSource.collectionPageViewController(self, viewControllerAt: indexPath.row)
            add(viewController, to: cell)
        }
        return cell
    }
    private func add(_ viewController: UIViewController, to cell: UICollectionViewCell) {
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            viewController.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        viewController.didMove(toParent: self)
    }
    // MARK: - UICollectionViewDelegate
    // MARK: - UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

internal class CollectionViewCell: UICollectionViewCell {
    var willPrepareForReuse: (() -> Void)?
    var index: Int = -1
    override func prepareForReuse() {
        super.prepareForReuse()
        willPrepareForReuse?()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        NotificationCenter.default.addObserver(forName: hideCellNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let self = self, let index = notification.userInfo?[showHideCellNotificationIndexParameterName] as? Int, index != self.index else { return }
            self.isHidden = true
        }
        NotificationCenter.default.addObserver(forName: showCellNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let self = self, let index = notification.userInfo?[showHideCellNotificationIndexParameterName] as? Int else { return }
            self.isHidden = false
        }
    }
}

fileprivate extension UICollectionView {
    var flowLayout: UICollectionViewFlowLayout? {
        return collectionViewLayout as? UICollectionViewFlowLayout
    }
}

internal class CollectionView: UICollectionView {
    private weak var snapshotView: UIView?
    private weak var imposedSnapshotView: UIView?
    func addSnapshot() {
        if let snapshotViewImage = makeSnapshotImage() {
            let snapshotView = UIImageView(image: snapshotViewImage)
            snapshotView.contentMode = .scaleAspectFill
            defer {
                self.snapshotView = snapshotView
            }
            snapshotView.frame = frame
            superview?.addSubview(snapshotView)
        }
    }
    
    func impose(image: UIImage, onCellAt index: Int) {
        let snapshotView = UIImageView(image: image)
        defer {
            self.imposedSnapshotView = snapshotView
        }
        
        switch flowLayout!.scrollDirection {
        case .horizontal:
            snapshotView.frame = CGRect(x: CGFloat(index) * bounds.width, y: 0, width: bounds.width, height: bounds.height)
        case .vertical:
            snapshotView.frame = CGRect(x: 0, y: CGFloat(index) * bounds.height, width: bounds.width, height: bounds.height)
        @unknown default:
            fatalError()
        }
        
        addSubview(snapshotView)
    }
    
    func removeSnapshot() {
        snapshotView?.removeFromSuperview()
    }
    
    func removeImposedSnapshot() {
        imposedSnapshotView?.removeFromSuperview()
    }
    
    func makeSnapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        
        superview?.drawHierarchy(in: frame, afterScreenUpdates: false)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let snapshotView = snapshotView {
            snapshotView.frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: (snapshotView.frame.height / snapshotView.frame.width) * frame.width))
        }
    }
}

fileprivate let hideCellNotification = NSNotification.Name(rawValue: "hideCellNotification")
fileprivate let showCellNotification = NSNotification.Name(rawValue: "showCellNotification")
fileprivate let showHideCellNotificationIndexParameterName = "index"
