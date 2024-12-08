//
//  FlightsViewModel.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import Foundation
import MapKit

protocol FlightsViewModelInterface {
    var numberOfRowsInComponent: Int { get }
    var numberOfComponents: Int { get }
    var annotations: [FlightAnnotation] { get }
    var request: StatesRequest { get }
    func viewDidLoad()
    func getCurrentState() -> (lomin: Double, lamin: Double, lomax: Double, lamax: Double)?
    func setMapView()
    func showFlightsButtonTapped()
    func filterCountriesButtonTapped()
    func pickerCancelButtonTapped()
    func pickerDoneButtonTapped(with selectedRow: Int)
    func regionDidChangeAnimated()
    func fetchUpdatedData()
    func pickerViewWillAppear()
    func pickerViewDidDisappear()
    func checkRegionStability()
    func filterDataWithSelectedCountry(selectedRow: Int)
    func titleForRow(row: Int) -> String?
}

extension FlightsViewModel {
    enum Constant {
        static let showAllDataIndex = 0
    }
}

final class FlightsViewModel {
    private weak var view: FlightsViewInterface?
    private let networkManager: NetworkManager
    private var states: [FlightState] = []
    private var filteredFlights: [FlightState] = []
    private var mappedCountries: [String] = []
    private var timer: Timer?
    private var isFiltered: Bool = false
    private var lastVisibleRegion: MKCoordinateRegion?
    private var lastChangeTimestamp: Date?
    private var regionCheckTimer: Timer?
    private var selectedCountry: String? = nil


    init(view: FlightsViewInterface?, networkManager: NetworkManager = NetworkManager.shared) {
        self.view = view
        self.networkManager = networkManager
    }

    private func fetchStates(request: StatesRequest, completion: @escaping()->()) {
        view?.showLoadingIndicator()
        networkManager.request(request: request, responseModel: StatesResponse.self) { [weak self] result in
            guard let self = self else { return }
            self.view?.hideLoadingIndicator()
            switch result {
            case .success(let response):
                self.states = response.states
                self.mappedCountries = ["Show All"] + Array(Set(response.states.map { $0.origin_country ?? "" })).sorted()
                completion()
            case .failure(let error):
                view?.showError(title: "Error", message: error.localizedDescription, buttonTitle: "OK", completion: {})
            }
        }
    }

    private func startTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            regionCheckTimer?.invalidate()  // Invalidate any existing timer
            regionCheckTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkRegionStability), userInfo: nil, repeats: true)
        }
    }

    private func timerInvalid() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            lastVisibleRegion = view?.region
            lastChangeTimestamp = Date()
        }
    }
}

extension FlightsViewModel: FlightsViewModelInterface {
    var annotations: [FlightAnnotation] {
        let filteredStates: [FlightState]
        if let selectedCountry = selectedCountry {
            filteredStates = states.filter { $0.origin_country == selectedCountry }
        } else {
            filteredStates = states
        }
        return filteredStates.compactMap { FlightAnnotation(flightState: $0) }
    }

    func regionDidChangeAnimated() {
        lastChangeTimestamp = Date()
    }
    
    var request: StatesRequest {
        let boundingBox = getCurrentState()
        return StatesRequest(lomin: boundingBox?.lomin, lamin: boundingBox?.lamin, lomax: boundingBox?.lomax, lamax: boundingBox?.lamax)
    }
    
    var numberOfRowsInComponent: Int {
        mappedCountries.count
    }

    var numberOfComponents: Int {
        1
    }

    func viewDidLoad() {
        view?.setupUI()
        view?.setupPickerView()
        fetchStates(request: request) { [weak self] in
            self?.setMapView()
            self?.startTimer()
        }
    }

    func getCurrentState() -> (lomin: Double, lamin: Double, lomax: Double, lamax: Double)? {
        let region = view?.region
        guard let centerLatitude = region?.center.latitude,
        let centerLongitude = region?.center.longitude,
        let latitudeDelta = region?.span.latitudeDelta,
        let longitudeDelta = region?.span.longitudeDelta else {return nil}
        let lamin = centerLatitude - (latitudeDelta / 2)
        let lamax = centerLatitude + (latitudeDelta / 2)
        let lomin = centerLongitude - (longitudeDelta / 2)
        let lomax = centerLongitude + (longitudeDelta / 2)
        return (lomin, lamin, lomax, lamax)
    }

    func setMapView() {
        view?.addAnnotationsToMap()
    }

    func showFlightsButtonTapped() {
        isFiltered = false
        fetchStates(request: request) { [weak self] in
            self?.setMapView()
            self?.timerInvalid()
        }
    }

    func filterCountriesButtonTapped() {
        regionCheckTimer?.invalidate()
        view?.showPickerView()
    }

    func pickerCancelButtonTapped() {
        view?.removeFromSuperview()
        startTimer()
    }

    func pickerDoneButtonTapped(with selectedRow: Int) {
        view?.removeFromSuperview()
        filterDataWithSelectedCountry(selectedRow: selectedRow)
        startTimer()
    }

    func fetchUpdatedData() {
        fetchStates(request: request) { [weak self] in
            guard let self = self else { return }
            isFiltered ? view?.addAnnotationsToMap() : setMapView()
        }
    }

    func filterDataWithSelectedCountry(selectedRow: Int) {
        if selectedRow == Constant.showAllDataIndex {
            setMapView()
            isFiltered = false
        } else {
            isFiltered = true
            let selectedCountry = mappedCountries[selectedRow]
            self.selectedCountry = selectedCountry
            view?.addAnnotationsToMap()
        }
    }

    @objc func checkRegionStability() {
        let currentRegion = view?.region

        if let lastRegion = lastVisibleRegion,
           lastRegion.center.latitude == currentRegion?.center.latitude &&
            lastRegion.center.longitude == currentRegion?.center.longitude &&
            lastRegion.span.latitudeDelta == currentRegion?.span.latitudeDelta &&
            lastRegion.span.longitudeDelta == currentRegion?.span.longitudeDelta {
            // The region has not changed
            if let lastTimestamp = lastChangeTimestamp,
               Date().timeIntervalSince(lastTimestamp) >= 5.0 {
                // Region is stable for 5 seconds, trigger the update
                fetchUpdatedData()
                lastChangeTimestamp = Date() // Reset the timestamp to avoid repeated updates
            }
        } else {
            // The region has changed, reset the timer
            print("Region has changed")
            lastVisibleRegion = currentRegion
            lastChangeTimestamp = Date()
        }
    }

    func titleForRow(row: Int) -> String? {
        mappedCountries[row]
    }

    func pickerViewWillAppear() {
        regionCheckTimer?.invalidate()
    }

    func pickerViewDidDisappear() {
        startTimer()
    }
}
