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
    
    // MARK: - Overrides
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        addCollectionView()
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
    override func prepareForReuse() {
        super.prepareForReuse()
        willPrepareForReuse?()
    }
}

fileprivate extension UICollectionView {
    var flowLayout: UICollectionViewFlowLayout? {
        return collectionViewLayout as? UICollectionViewFlowLayout
    }
}

internal class CollectionView: UICollectionView {
    private weak var snapshotView: UIView?
    func addSnapshot() {
        if let snapshotViewImage = makeSnapshotImage() {
            let snapshotView = UIImageView(image: snapshotViewImage)
            defer {
                self.snapshotView = snapshotView
            }
            snapshotView.frame = frame
            superview?.addSubview(snapshotView)
        }
    }
    
    func removeSnapshot() {
        snapshotView?.removeFromSuperview()
    }
    
    private func makeSnapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        
        superview?.drawHierarchy(in: frame, afterScreenUpdates: false)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
