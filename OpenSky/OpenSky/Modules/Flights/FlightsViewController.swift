//
//  FlightsViewController.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import UIKit
import MapKit

protocol FlightsViewInterface: AnyObject {
    func setupUI()
}

class FlightsViewController: UIViewController {

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var countriesButton: UIButton!

    private lazy var viewModel = FlightsViewModel(view: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()
    }
}

extension FlightsViewController: MKMapViewDelegate {}

extension FlightsViewController: FlightsViewInterface {
    func setupUI() {
        mapView.delegate = self
        countriesButton.layer.cornerRadius = countriesButton.frame.height / 2
    }
}
