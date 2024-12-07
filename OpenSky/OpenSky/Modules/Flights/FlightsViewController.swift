//
//  FlightsViewController.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import UIKit

protocol FlightsViewInterface: AnyObject {}

class FlightsViewController: UIViewController {

    private lazy var viewModel = FlightsViewModel(view: self)

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension FlightsViewController: FlightsViewInterface {}
