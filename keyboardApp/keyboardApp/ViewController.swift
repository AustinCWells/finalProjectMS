//
//  ViewController.swift
//  keyboardApp
//
//  Created by Austin Wells on 5/4/15.
//  Copyright (c) 2015 Austin Wells. All rights reserved.
//

import UIKit

class ViewController: UIViewController {


    @IBOutlet weak var inputBox: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        inputBox.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

