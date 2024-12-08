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
    func showFlightsButtonTapped()
    func filterCountriesButtonTapped()
    func pickerCancelButtonTapped()
    func pickerDoneButtonTapped(with selectedRow: Int)
    func regionDidChangeAnimated()
    func pickerViewWillAppear()
    func pickerViewDidDisappear()
    func filterDataWithSelectedCountry(selectedRow: Int)
    func titleForRow(row: Int) -> String?
}

extension FlightsViewModel {
    enum Constant {
        static let errorTitle: String = "Error"
        static let errorOkButtonTitle: String = "OK"
        static let pickerViewShowAllTitle: String = "Show All"
        static let showAllDataIndex: Int = 0
        static let numberOfComponents: Int = 1
        static let timeIntervalSince: Double = 5.0
    }
}

final class FlightsViewModel {
    private weak var view: FlightsViewInterface?
    private let networkManager: NetworkManager
    private var states: [FlightState] = []
    private var mappedCountries: [String] = []
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
        Task {
            self.view?.hideLoadingIndicator()
            do {
                let response: StatesResponse = try await NetworkManager.shared.request(
                    request: request,
                    responseModel: StatesResponse.self
                )
                self.states = response.states
                self.mappedCountries = [Constant.pickerViewShowAllTitle] + Array(Set(response.states.map { $0.origin_country ?? "" })).sorted()
                completion()
            } catch let error as NetworkError {
                view?.showError(title: Constant.errorTitle, message: error.localizedDescription, buttonTitle: Constant.errorOkButtonTitle, completion: {})
            } catch {
                view?.showError(title: Constant.errorTitle, message: error.localizedDescription, buttonTitle: Constant.errorOkButtonTitle, completion: {})
            }
        }
    }

    private func startTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            regionCheckTimer?.invalidate()
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

    @objc func checkRegionStability() {
        let currentRegion = view?.region
        if let lastRegion = lastVisibleRegion,
           lastRegion.center.latitude == currentRegion?.center.latitude &&
            lastRegion.center.longitude == currentRegion?.center.longitude &&
            lastRegion.span.latitudeDelta == currentRegion?.span.latitudeDelta &&
            lastRegion.span.longitudeDelta == currentRegion?.span.longitudeDelta {
            if let lastTimestamp = lastChangeTimestamp,
               Date().timeIntervalSince(lastTimestamp) >= Constant.timeIntervalSince {
                fetchStates(request: request) { [weak self] in
                    guard let self = self else { return }
                    view?.addAnnotationsToMap()
                }
                lastChangeTimestamp = Date()
            }
        } else {
            lastVisibleRegion = currentRegion
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
        Constant.numberOfComponents
    }

    func viewDidLoad() {
        view?.setupUI()
        view?.setupPickerView()
        fetchStates(request: request) { [weak self] in
            self?.view?.addAnnotationsToMap()
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

    func showFlightsButtonTapped() {
        selectedCountry = nil
        fetchStates(request: request) { [weak self] in
            self?.view?.addAnnotationsToMap()
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

    func filterDataWithSelectedCountry(selectedRow: Int) {
        if selectedRow == Constant.showAllDataIndex {
            selectedCountry = nil
        } else {
            let selectedCountry = mappedCountries[selectedRow]
            self.selectedCountry = selectedCountry
            view?.addAnnotationsToMap()
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
