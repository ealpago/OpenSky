//
//  FlightsViewController.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import UIKit
import MapKit


#warning("I am using Xcode version 15.2. If you use guard let self in this version, you do not need to write extra self. If you are using an older Xcode version, you may get an error.")

//MARK: Interface
protocol FlightsViewInterface: ProgressIndicatorPresentable, AlertPresentable {
    var region: MKCoordinateRegion { get }

    func setupUI()
    func setupPickerView()
    func addAnnotationsToMap()
    func showPickerView()
    func removeFromSuperview()
}

//MARK: ViewController
final class FlightsViewController: UIViewController {

    //MARK: Outlets
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var showFlightsButton: UIButton!
    @IBOutlet private weak var filterCountriesButton: UIButton!

    //MARK: Properties
    private lazy var viewModel = FlightsViewModel(view: self)
    private let pickerView = UIPickerView()
    private let pickerToolbar = UIToolbar()

    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //This type of code blocks are better for unit testing and View Controllers become quite dummy, all logic operations should be left to viewModel
        viewModel.viewDidLoad()
    }

    //MARK: Functions
    @objc func pickerCancelButtonTapped() {
        viewModel.pickerCancelButtonTapped()
    }

    @objc func pickerDoneButtonTapped() {
        viewModel.pickerDoneButtonTapped(with: pickerView.selectedRow(inComponent: 0))
    }

    //MARK: Actions
    @IBAction private func showFlightsButtonTapped() {
        viewModel.showFlightsButtonTapped()
    }

    @IBAction private func filterCountriesButtonTapped() {
        viewModel.filterCountriesButtonTapped()
    }
}

//MARK: MKMapViewDelegate
extension FlightsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Check if the annotation is of the type FlightAnnotation
        guard let flightAnnotation = annotation as? FlightAnnotation else { return nil }
        let identifier = "FlightAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        // If no reusable annotation view was found (i.e., it's the first time using this annotation type)
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: flightAnnotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .system)
        } else {
            // If the annotation view is reused, update the annotation to ensure it's the correct one
            annotationView?.annotation = flightAnnotation
        }
        //If the annotation view is an instance of MKMarkerAnnotationView (which it should be)
        if let markerAnnotationView = annotationView as? MKMarkerAnnotationView {
            markerAnnotationView.glyphImage = UIImage(systemName: "airplane")
        }
        return annotationView
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        viewModel.regionDidChangeAnimated()
    }
}

//MARK: UIPickerViewDelegate, UIPickerViewDataSource
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

//MARK: Interface Extension
extension FlightsViewController: FlightsViewInterface {
    var region: MKCoordinateRegion {
        mapView.region
    }

    func removeFromSuperview() {
        view.subviews.last?.removeFromSuperview()
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
