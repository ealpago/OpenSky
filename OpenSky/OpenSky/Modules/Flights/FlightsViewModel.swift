//
//  FlightsViewModel.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import Foundation

protocol FlightsViewModelInterface {
    func viewDidLoad(request: StatesRequest)
    func setMapView()
    func showFlightsButtonTapped(request: StatesRequest)
    func filterCountriesButtonTapped(originCountry: String?)
    func fetchUpdatedData(request: StatesRequest)
}

final class FlightsViewModel {
    private weak var view: FlightsViewInterface?
    private let networkManager: NetworkManager?
    private var states: [FlightState] = []
    private var timer: Timer?

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
                completion()
            case .failure(let error):
                print(error.self)
            }
        }
    }
}

extension FlightsViewModel: FlightsViewModelInterface {
    func viewDidLoad(request: StatesRequest) {
        view?.setupUI()
        fetchStates(request: request) { [weak self] in
            guard let self = self else { return }
            self.setMapView()
        }
    }

    func setMapView() {
        view?.addAnnotationsToMap(states: states)
    }

    func showFlightsButtonTapped(request: StatesRequest) {
        fetchStates(request: request) { [weak self] in
            guard let self = self else { return }
            self.setMapView()
            view?.timerInvalid()
        }
    }

    func filterCountriesButtonTapped(originCountry: String?) {}

    func fetchUpdatedData(request: StatesRequest) {
        fetchStates(request: request) { [weak self] in
            guard let self = self else { return }
            self.setMapView()
        }
    }
}
