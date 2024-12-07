//
//  FlightsViewModel.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import Foundation

protocol FlightsViewModelInterface {
    func viewDidLoad()
}

final class FlightsViewModel {

    private weak var view: FlightsViewInterface?
    private let networkManager: NetworkManager?

    init(view: FlightsViewInterface?, networkManager: NetworkManager = NetworkManager.shared) {
        self.view = view
        self.networkManager = networkManager
    }
}

extension FlightsViewModel: FlightsViewModelInterface {
    func viewDidLoad() {
        view?.setupUI()
    }
}
