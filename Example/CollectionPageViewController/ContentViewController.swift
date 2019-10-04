//
//  ContentViewController.swift
//  CollectionPageViewController_Example
//
//  Created by Ahmed Khalaf on 10/4/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {
    var index = 0 {
        didSet {
            guard isViewLoaded else { return }
            label.text = "\(index)"
            view.backgroundColor = [UIColor.red, .green, .blue][circular: index]
        }
    }
    @IBOutlet private weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        index = Int(index)
    }
}

fileprivate extension Array {
    subscript(circular index: Index) -> Element {
        return self[index % count]
    }
}
