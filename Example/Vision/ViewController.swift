//
//  ViewController.swift
//  Vision
//
//  Created by ly0u on 04/24/2022.
//  Copyright (c) 2022 ly0u. All rights reserved.
//

import UIKit
import Vision



class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        FPSMonitor.shared.start()
        APMTracker.duration(name: "test") {
            print("test")
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

