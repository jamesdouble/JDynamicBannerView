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
        var views: [UIView] = []
        for idx in 0..<1 {
            let imgName = "test\(idx+1)"
            let img = UIImage(named: imgName)
            let imgView = UIImageView(image: img)
            imgView.layer.cornerRadius = 5.0
            imgView.clipsToBounds = true
            views.append(imgView)
        }
        test = DynamicCycleScrollView(frame: CGRect(origin: CGPoint(x: 20, y: 100), size: CGSize(width: 340, height: 100)), views: views)
        test.clickBlock = { (idx) in
            print(idx)
        }
        test.tailWidth = 20.0
        test.layer.borderWidth = 1.0
        self.view.addSubview(test)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}



