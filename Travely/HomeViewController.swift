//
//  HomeViewController.swift
//  Travely
//
//  Created by Phat is here on 3/17/25.
//

import UIKit

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        view.backgroundColor = .white
        title = "Home"

        let welcomeLabel = UILabel()
        welcomeLabel.text = "Welcome to the Travel App!"
        welcomeLabel.font = UIFont.boldSystemFont(ofSize: 20)
        welcomeLabel.textAlignment = .center
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(welcomeLabel)

        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
