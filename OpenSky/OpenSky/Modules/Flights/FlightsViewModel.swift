//
//  FlightsViewModel.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import Foundation
import MapKit

//MARK: Interface
protocol FlightsViewModelInterface {
    var numberOfRowsInComponent: Int { get }
    var numberOfComponents: Int { get }
    var annotations: [FlightAnnotation] { get }
    func viewDidLoad()
    func showFlightsButtonTapped()
    func filterCountriesButtonTapped()
    func pickerCancelButtonTapped()
    func pickerDoneButtonTapped(with selectedRow: Int)
    func regionDidChangeAnimated()
    func pickerViewWillAppear()
    func pickerViewDidDisappear()
    func titleForRow(row: Int) -> String?
}

//MARK: Constants
extension FlightsViewModel {
    enum Constant {
        static let errorTitle: String = "Error"
        static let errorOkButtonTitle: String = "OK"
        static let pickerViewShowAllTitle: String = "Show All"
        static let numberOfComponents: Int = 1
        static let timeIntervalSince: Double = 5.0
    }
}

//MARK: ViewModel
final class FlightsViewModel {

    //MARK: Properties
    private weak var view: FlightsViewInterface?
    private let networkManager: NetworkManager
    private var states: [FlightState] = []
    private var mappedCountries: [String] = []
    private var lastVisibleRegion: MKCoordinateRegion?
    private var lastChangeTimestamp: Date?
    private var regionCheckTimer: Timer?
    private var selectedCountry: String? = nil
    private var request: StatesRequest {
        let boundingBox = getCurrentState()
        return StatesRequest(lomin: boundingBox?.lomin, lamin: boundingBox?.lamin, lomax: boundingBox?.lomax, lamax: boundingBox?.lamax)
    }

    //MARK: init
    init(view: FlightsViewInterface?, networkManager: NetworkManager = NetworkManager.shared) {
        self.view = view
        self.networkManager = networkManager
    }

    //MARK: Functions
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
                self.mappedCountries = Array(Set(response.states.map { $0.origin_country ?? "" })).sorted()
                completion()
            } catch let error as NetworkError {
                view?.showError(title: Constant.errorTitle, message: error.localizedDescription, buttonTitle: Constant.errorOkButtonTitle, completion: {})
            } catch {
                view?.showError(title: Constant.errorTitle, message: error.localizedDescription, buttonTitle: Constant.errorOkButtonTitle, completion: {})
            }
        }
    }

    private func getCurrentState() -> (lomin: Double, lamin: Double, lomax: Double, lamax: Double)? {
        //This code block provides the Location for the request using where you are standing on the map
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

    private func filterDataWithSelectedCountry(selectedRow: Int) {
            let selectedCountry = mappedCountries[selectedRow]
            self.selectedCountry = selectedCountry
            view?.addAnnotationsToMap()
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
            self?.lastVisibleRegion = self?.view?.region
            self?.lastChangeTimestamp = Date()
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
                    self?.view?.addAnnotationsToMap()
                }
                lastChangeTimestamp = Date()
            }
        } else {
            lastVisibleRegion = currentRegion
            lastChangeTimestamp = Date()
        }
    }
}

//MARK: Interface Extension
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
