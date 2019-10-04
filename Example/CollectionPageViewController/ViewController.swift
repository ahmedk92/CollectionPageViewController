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
    
    private lazy var collectionPageViewController: CollectionPageViewController = {
        let cpvc = CollectionPageViewController(navigationOrientation: .horizontal)
        cpvc.dataSource = self
        return cpvc
    }()
    
    private func addCollectionPageViewController() {
        collectionPageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionPageViewController.view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: collectionPageViewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: collectionPageViewController.view.trailingAnchor),
            view.topAnchor.constraint(equalTo: collectionPageViewController.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: collectionPageViewController.view.bottomAnchor),
        ])
    }
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addCollectionPageViewController()
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

