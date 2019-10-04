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
    public init(navigationOrientation: NavigationOrientation) {
        self.navigationOrientation = navigationOrientation
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
    }
    
    open var navigationOrientation: NavigationOrientation
    open weak var dataSource: CollectionPageViewControllerDataSource?
    
    private let collectionViewCellReuseIdentifier = "cell"
    private lazy var collectionView: UICollectionView = {
        let cvLayout = UICollectionViewFlowLayout()
        cvLayout.scrollDirection = navigationOrientation.collectionViewScrollDirection
        let cv = UICollectionView(frame: .zero, collectionViewLayout: cvLayout)
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
