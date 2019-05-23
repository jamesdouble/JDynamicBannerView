//
//  ViewController.swift
//  DynamicBannerView
//
//  Created by 郭介騵 on 2018/5/3.
//  Copyright © 2018年 james12345. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var test: DynamicCycleScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        test = DynamicCycleScrollView(frame: CGRect(origin: CGPoint(x: 5, y: 100), size: CGSize(width: 340, height: 100)))
        test.infinityScrolling = false
        test.edges = UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 5)
        test.setView(viewCount: 4) { (index) -> UIView in
            let text = "test1"
            let img = UIImage(named: text)
            let imgView = UIImageView(image: img)
            imgView.layer.cornerRadius = 5.0
            imgView.clipsToBounds = true
            return imgView
        }
        test.clickBlock = { (idx) in
            print(idx)
        }
        test.autoScrolling = false
        test.layer.borderWidth = 1.0
        self.view.addSubview(test)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}



