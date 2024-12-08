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
    func addAnnotationsToMap(states: [FlightState])
    func getCurrentState(from mapView: MKMapView) -> (lomin: Double, lamin: Double, lomax: Double, lamax: Double)
    func timerInvalid()
}

class FlightsViewController: UIViewController {
    var lastVisibleRegion: MKCoordinateRegion?
    var lastChangeTimestamp: Date?
    var regionCheckTimer: Timer?

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var showFlightsButton: UIButton!
    @IBOutlet private weak var filterCountriesButton: UIButton!

    private lazy var viewModel = FlightsViewModel(view: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad(request: request)
        regionCheckTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkRegionStability), userInfo: nil, repeats: true)

    }

    @IBAction private func showFlightsButtonTapped(_ sender: UIButton) {
        viewModel.showFlightsButtonTapped(request: request)
    }

    @IBAction private func filterCountriesButtonTapped(_ sender: UIButton) {
        viewModel.filterCountriesButtonTapped(originCountry: selectedOriginCountry)
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

    deinit {
        regionCheckTimer?.invalidate() // Invalidate the timer when the view controller is deinitialized
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

extension FlightsViewController: FlightsViewInterface {
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
        filterCountriesButton.layer.cornerRadius = filterCountriesButton.frame.height / 2
        showFlightsButton.layer.cornerRadius = showFlightsButton.frame.height / 2
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
}
