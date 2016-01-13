//
//  ViewController.swift
//  SwiftReflect
//
//  Created by fenggeren on 15/12/17.
//  Copyright © 2015年 fenggeren. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        test2()
    }
    
    func test2() {
        let data = [[
            "name": "abc", "height": 32.2, "weigh": 33.3, "address": "太阳城",
            "childNames": ["abc", "bcd", "def"],
            "pp": ["pet": ["name": "xa", "d": ["weigh": 32]]],
            "ps": ["pets": [["name": "xa", "d": ["weigh": 32]], ["name": "xa", "d": ["weigh": 32]], ["name": "xa", "d": ["weigh": 32]]]]
            ]]
        
        let model = [Person](adata: data)
        print(model.toString)
    }
    
}


class Dog: NSObject {
    var name: String!
    var d_weigh: String!
}

class Person: NSObject {

    var name: String!
    var address = "地球村"
    
    var childNames: [String]?
    
    var pp_pet: Dog?
    
    var ps_pets: [Dog]?
}













