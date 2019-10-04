//
//  ViewController.swift
//  CollectionPageViewController
//
//  Created by ahmedk92 on 10/04/2019.
//  Copyright (c) 2019 ahmedk92. All rights reserved.
//

import UIKit
import CollectionPageViewController

class ViewController: UIViewController, CollectionPageViewControllerDataSource {
    
    @IBOutlet private weak var navigationOrientationButton: UIButton!
    @IBOutlet private weak var collectionPageViewControllerContainerView: UIView!
    
    private lazy var collectionPageViewController: CollectionPageViewController = {
        let cpvc = CollectionPageViewController()
        cpvc.navigationOrientation = .horizontal
        cpvc.dataSource = self
        return cpvc
    }()
    
    private func addCollectionPageViewController() {
        collectionPageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        collectionPageViewControllerContainerView.addSubview(collectionPageViewController.view)
        NSLayoutConstraint.activate([
            collectionPageViewControllerContainerView.leadingAnchor.constraint(equalTo: collectionPageViewController.view.leadingAnchor),
            collectionPageViewControllerContainerView.trailingAnchor.constraint(equalTo: collectionPageViewController.view.trailingAnchor),
            collectionPageViewControllerContainerView.topAnchor.constraint(equalTo: collectionPageViewController.view.topAnchor),
            collectionPageViewControllerContainerView.bottomAnchor.constraint(equalTo: collectionPageViewController.view.bottomAnchor),
        ])
    }
    
    @IBAction private func navigtionOrientationButtonTapped(_ sender: UIButton) {
        collectionPageViewController.navigationOrientation = collectionPageViewController.navigationOrientation == .horizontal ? .vertical : .horizontal
        sender.setTitle("\(collectionPageViewController.navigationOrientation)", for: .normal)
    }
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addCollectionPageViewController()
        navigationOrientationButton.setTitle("\(collectionPageViewController.navigationOrientation)", for: .normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CollectionPageViewControllerDataSource
    func numberOfViewControllers(in collectionPageViewController: CollectionPageViewController) -> Int {
        return 8
    }
    
    func collectionPageViewController(_ collectionPageViewController: CollectionPageViewController, viewControllerAt index: Int) -> UIViewController {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ContentViewController") as! ContentViewController
        vc.index = index
        return vc
    }

}

