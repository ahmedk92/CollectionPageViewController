//
//  ViewController.swift
//  CollectionPageViewController
//
//  Created by ahmedk92 on 10/04/2019.
//  Copyright (c) 2019 ahmedk92. All rights reserved.
//

import UIKit
import CollectionPageViewController

class ViewController: UIViewController, CollectionPageViewControllerDataSource, CollectionPageViewControllerDelegate {
    
    @IBOutlet private weak var navigationOrientationButton: UIButton!
    @IBOutlet private weak var collectionPageViewControllerContainerView: UIView!
    
    private lazy var collectionPageViewController: CollectionPageViewController = {
        let cpvc = CollectionPageViewController()
        cpvc.navigationOrientation = .horizontal
        cpvc.dataSource = self
        cpvc.delegate = self
        return cpvc
    }()
    
    private func addCollectionPageViewController() {
        addChild(collectionPageViewController)
        defer {
            collectionPageViewController.didMove(toParent: self)
        }
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
    
    private var textFieldEditingChangedTimer: Timer?
    @IBAction private func indexTextFieldEditingChanged(_ sender: UITextField) {
        textFieldEditingChangedTimer?.invalidate()
        textFieldEditingChangedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] (_) in
            guard let self = self, let index = Int(sender.text ?? "") else { return }
            defer {
                sender.resignFirstResponder()
            }
            
            self.collectionPageViewController.index = index
        })
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
        return 1024
    }
    
    func collectionPageViewController(_ collectionPageViewController: CollectionPageViewController, viewControllerAt index: Int) -> UIViewController {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ContentViewController") as! ContentViewController
        vc.index = index
        return vc
    }
    
    // MARK: - CollectionPageViewControllerDelegate
    func collectionPageViewController(_ collectionPageViewController: CollectionPageViewController, willNavigateTo index: Int) {
        print("willNavigateTo index: \(index)")
    }
    
    func collectionPageViewController(_ collectionPageViewController: CollectionPageViewController, didNavigateTo index: Int) {
        print("didNavigateTo index: \(index)")
    }
    
    func collectionPageViewController(_ collectionPageViewController: CollectionPageViewController, isNowAt index: Int) {
        print("isNowAt index: \(index)")
    }

}

