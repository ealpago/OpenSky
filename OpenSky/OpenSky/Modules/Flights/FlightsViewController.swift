//
//  FlightsViewController.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import UIKit
import MapKit

protocol FlightsViewInterface: ProgressIndicatorPresentable, AlertPresentable {
    var region: MKCoordinateRegion { get }
    func setupUI()
    func setupPickerView()
    func addAnnotationsToMap()
    func showPickerView()
    func removeFromSuperview()
}

final class FlightsViewController: UIViewController {

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var showFlightsButton: UIButton!
    @IBOutlet private weak var filterCountriesButton: UIButton!

    private lazy var viewModel = FlightsViewModel(view: self)
    private let pickerView = UIPickerView()
    private let pickerToolbar = UIToolbar()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()
    }

    @IBAction private func showFlightsButtonTapped() {
        viewModel.showFlightsButtonTapped()
    }

    @IBAction private func filterCountriesButtonTapped() {
        viewModel.filterCountriesButtonTapped()
    }

    @objc func checkRegionStability() {
        viewModel.checkRegionStability()
    }

    @objc func fetchUpdatedData() {
        viewModel.fetchUpdatedData()
    }

    @objc func pickerCancelButtonTapped() {
        viewModel.pickerCancelButtonTapped()
    }

    @objc func pickerDoneButtonTapped() {
        viewModel.pickerDoneButtonTapped(with: pickerView.selectedRow(inComponent: 0))
    }
}

extension FlightsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let flightAnnotation = annotation as? FlightAnnotation else { return nil }
        let identifier = "FlightAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: flightAnnotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .system)
        } else {
            annotationView?.annotation = flightAnnotation
        }
        if let markerAnnotationView = annotationView as? MKMarkerAnnotationView {
            markerAnnotationView.glyphImage = UIImage(systemName: "airplane")
        }
        return annotationView
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        viewModel.regionDidChangeAnimated()
    }
}

extension FlightsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        viewModel.numberOfComponents
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        viewModel.numberOfRowsInComponent
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        viewModel.titleForRow(row: row)
    }

    func pickerViewWillAppear(_ pickerView: UIPickerView) {
        viewModel.pickerViewWillAppear()
    }

    func pickerViewDidDisappear(_ pickerView: UIPickerView) {
        viewModel.pickerViewDidDisappear()
    }
}

extension FlightsViewController: FlightsViewInterface {
    func removeFromSuperview() {
        view.subviews.last?.removeFromSuperview()
    }
    
    var region: MKCoordinateRegion {
        mapView.region
    }

    func setupUI() {
        mapView.delegate = self
        pickerView.delegate = self
        pickerView.dataSource = self
        filterCountriesButton.layer.cornerRadius = filterCountriesButton.frame.height / 2
        showFlightsButton.layer.cornerRadius = showFlightsButton.frame.height / 2
    }

    func setupPickerView() {
        pickerToolbar.sizeToFit()
        pickerToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(pickerCancelButtonTapped)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(pickerDoneButtonTapped))
        ]
    }

    func addAnnotationsToMap() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(viewModel.annotations)
        }
    }

    func showPickerView() {
        let pickerContainer = UIView(frame: CGRect(x: 0, y: view.bounds.height - 300, width: view.bounds.width, height: 300))
        pickerContainer.backgroundColor = .white
        pickerView.frame = CGRect(x: 0, y: 50, width: view.bounds.width, height: 250)
        pickerToolbar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
        pickerContainer.addSubview(pickerToolbar)
        pickerContainer.addSubview(pickerView)
        view.addSubview(pickerContainer)
    }
}
