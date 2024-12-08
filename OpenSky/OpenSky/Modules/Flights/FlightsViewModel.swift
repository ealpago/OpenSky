//
//  FlightsViewModel.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import Foundation

protocol FlightsViewModelInterface {
    var numberOfRowsInComponent: Int { get }
    func viewDidLoad(request: StatesRequest)
    func setMapView()
    func showFlightsButtonTapped(request: StatesRequest)
    func filterCountriesButtonTapped()
    func fetchUpdatedData(request: StatesRequest)
    func filterDataWithSelectedCountry(selectedRow: Int)
    func titleForRow(row: Int) -> String?
}

final class FlightsViewModel {
    private weak var view: FlightsViewInterface?
    private let networkManager: NetworkManager?
    private var states: [FlightState] = []
    private var filteredFlights: [FlightState] = []
    private var mappedCountries: [String] = []
    private var timer: Timer?
    private var isFiltered: Bool = false

    init(view: FlightsViewInterface?, networkManager: NetworkManager = NetworkManager.shared) {
        self.view = view
        self.networkManager = networkManager
    }

    private func fetchStates(request: StatesRequest, completion: @escaping()->()) {
        view?.showLoadingIndicator()
        NetworkManager.shared.request(request: request, responseModel: StatesResponse.self) { [weak self] result in
            guard let self = self else { return }
            self.view?.hideLoadingIndicator()
            switch result {
            case .success(let response):
                self.states = response.states
                self.mappedCountries = ["Show All"] + Array(Set(response.states.map { $0.origin_country ?? "" })).sorted()
                completion()
            case .failure(let error):
                print(error.self)
            }
        }
    }
}

extension FlightsViewModel: FlightsViewModelInterface {
    var numberOfRowsInComponent: Int {
        return mappedCountries.count
    }

    func viewDidLoad(request: StatesRequest) {
        view?.setupUI()
        view?.setupPickerView()
        fetchStates(request: request) { [weak self] in
            guard let self = self else { return }
            self.setMapView()
            view?.startTimer()
        }
    }

    func setMapView() {
        view?.addAnnotationsToMap(states: states)
    }

    func showFlightsButtonTapped(request: StatesRequest) {
        isFiltered = false
        fetchStates(request: request) { [weak self] in
            guard let self = self else { return }
            self.setMapView()
            view?.timerInvalid()
        }
    }

    func filterCountriesButtonTapped() {
        view?.showPickerView()
    }

    func fetchUpdatedData(request: StatesRequest) {
        fetchStates(request: request) { [weak self] in
            guard let self = self else { return }
            isFiltered ? view?.addAnnotationsToMap(states: self.filteredFlights) : self.setMapView()
        }
    }

    func filterDataWithSelectedCountry(selectedRow: Int) {
        if selectedRow == 0 {
            setMapView()
            isFiltered = false
        } else {
            isFiltered = true
            let selectedCountry = mappedCountries[selectedRow]
            self.filteredFlights = states.filter{$0.origin_country == selectedCountry}
            view?.addAnnotationsToMap(states: filteredFlights)
        }
    }


    func titleForRow(row: Int) -> String? {
        return mappedCountries[row]
    }
}
