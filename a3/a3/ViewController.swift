//
//  ViewController.swift
//  a3
//
//  Created by Ngoc Tuan Cao on 4/5/2025.
//
import Firebase
import FirebaseFirestore
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.

            let db = Firestore.firestore()
            print("\nINITIALIZED FIRESTORE APP \(db.app.name)\n")
    }

}

