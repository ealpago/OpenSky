//
//  FlightsViewController.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import UIKit
import MapKit

protocol FlightsViewInterface: ProgressIndicatorPresentable {
    var request: StatesRequest { get }
    var selectedOriginCountry: String { get }
    func setupUI()
    func setupPickerView()
    func addAnnotationsToMap(states: [FlightState])
    func getCurrentState(from mapView: MKMapView) -> (lomin: Double, lamin: Double, lomax: Double, lamax: Double)
    func startTimer()
    func timerInvalid()
    func showPickerView()
}

class FlightsViewController: UIViewController {
    var lastVisibleRegion: MKCoordinateRegion?
    var lastChangeTimestamp: Date?
    var regionCheckTimer: Timer?

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var showFlightsButton: UIButton!
    @IBOutlet private weak var filterCountriesButton: UIButton!

    private lazy var viewModel = FlightsViewModel(view: self)
    private let pickerView = UIPickerView()
    private let pickerToolbar = UIToolbar()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad(request: request)
    }

    @IBAction private func showFlightsButtonTapped(_ sender: UIButton) {
        viewModel.showFlightsButtonTapped(request: request)
    }

    @IBAction private func filterCountriesButtonTapped(_ sender: UIButton) {
        regionCheckTimer?.invalidate()
        viewModel.filterCountriesButtonTapped()
    }

    @objc func checkRegionStability() {
        let currentRegion = mapView.region

        if let lastRegion = lastVisibleRegion,
           lastRegion.center.latitude == currentRegion.center.latitude &&
            lastRegion.center.longitude == currentRegion.center.longitude &&
            lastRegion.span.latitudeDelta == currentRegion.span.latitudeDelta &&
            lastRegion.span.longitudeDelta == currentRegion.span.longitudeDelta {
            // The region has not changed
            if let lastTimestamp = lastChangeTimestamp,
               Date().timeIntervalSince(lastTimestamp) >= 5.0 {
                // Region is stable for 5 seconds, trigger the update
                viewModel.fetchUpdatedData(request: request)
                lastChangeTimestamp = Date() // Reset the timestamp to avoid repeated updates
            }
        } else {
            // The region has changed, reset the timer
            lastVisibleRegion = currentRegion
            lastChangeTimestamp = Date()
        }
    }

    @objc func fetchUpdatedData() {
        viewModel.fetchUpdatedData(request: request)
    }

    @objc func cancelPicker() {
        view.subviews.last?.removeFromSuperview()
        startTimer()
    }

    @objc func donePicker() {
        view.subviews.last?.removeFromSuperview()
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        viewModel.filterDataWithSelectedCountry(selectedRow: selectedRow)
        startTimer()
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
        lastChangeTimestamp = Date()
    }
}

extension FlightsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        viewModel.numberOfRowsInComponent
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        viewModel.titleForRow(row: row)
    }

    func pickerViewWillAppear(_ pickerView: UIPickerView) {
        regionCheckTimer?.invalidate()
    }

    func pickerViewDidDisappear(_ pickerView: UIPickerView) {
        startTimer()
    }
}

extension FlightsViewController: FlightsViewInterface {

    func startTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            regionCheckTimer?.invalidate()  // Invalidate any existing timer
            regionCheckTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkRegionStability), userInfo: nil, repeats: true)
        }
    }

    func timerInvalid() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            lastVisibleRegion = mapView.region
            lastChangeTimestamp = Date()
        }
    }

    var request: StatesRequest {
        let boundingBox = getCurrentState(from: mapView)
        return StatesRequest(lomin: boundingBox.lomin, lamin: boundingBox.lamin, lomax: boundingBox.lomax, lamax: boundingBox.lamax)
    }

    var selectedOriginCountry: String {
        ""
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
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPicker)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePicker))
        ]
    }

    func addAnnotationsToMap(states: [FlightState]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            mapView.removeAnnotations(mapView.annotations)
            let annotations = states.compactMap { state -> FlightAnnotation? in
                guard state.latitude != nil && state.longitude != nil else { return nil }
                return FlightAnnotation(flightState: state)
            }
            mapView.addAnnotations(annotations)
        }
    }

    func getCurrentState(from mapView: MKMapView) -> (lomin: Double, lamin: Double, lomax: Double, lamax: Double) {
        let region = mapView.region
        let centerLatitude = region.center.latitude
        let centerLongitude = region.center.longitude
        let latitudeDelta = region.span.latitudeDelta
        let longitudeDelta = region.span.longitudeDelta
        let lamin = centerLatitude - (latitudeDelta / 2)
        let lamax = centerLatitude + (latitudeDelta / 2)
        let lomin = centerLongitude - (longitudeDelta / 2)
        let lomax = centerLongitude + (longitudeDelta / 2)
        return (lomin, lamin, lomax, lamax)
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
