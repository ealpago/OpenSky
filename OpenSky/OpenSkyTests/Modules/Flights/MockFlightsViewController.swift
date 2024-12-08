//
//  MockFlightsViewController.swift
//  OpenSkyTests
//
//  Created by Emre Alpago on 9.12.2024.
//

import MapKit
@testable import OpenSky

final class MockFlightsViewController: FlightsViewInterface {

    var invokedRegionGetter = false
    var invokedRegionGetterCount = 0
    var stubbedRegion: MKCoordinateRegion!

    var region: MKCoordinateRegion {
        invokedRegionGetter = true
        invokedRegionGetterCount += 1
        return stubbedRegion
    }

    var invokedSetupUI = false
    var invokedSetupUICount = 0

    func setupUI() {
        invokedSetupUI = true
        invokedSetupUICount += 1
    }

    var invokedSetupPickerView = false
    var invokedSetupPickerViewCount = 0

    func setupPickerView() {
        invokedSetupPickerView = true
        invokedSetupPickerViewCount += 1
    }

    var invokedAddAnnotationsToMap = false
    var invokedAddAnnotationsToMapCount = 0

    func addAnnotationsToMap() {
        invokedAddAnnotationsToMap = true
        invokedAddAnnotationsToMapCount += 1
    }

    var invokedShowPickerView = false
    var invokedShowPickerViewCount = 0

    func showPickerView() {
        invokedShowPickerView = true
        invokedShowPickerViewCount += 1
    }

    var invokedRemoveFromSuperview = false
    var invokedRemoveFromSuperviewCount = 0

    func removeFromSuperview() {
        invokedRemoveFromSuperview = true
        invokedRemoveFromSuperviewCount += 1
    }

    var invokedShowLoadingIndicator = false
    var invokedShowLoadingIndicatorCount = 0

    func showLoadingIndicator() {
        invokedShowLoadingIndicator = true
        invokedShowLoadingIndicatorCount += 1
    }

    var invokedHideLoadingIndicator = false
    var invokedHideLoadingIndicatorCount = 0

    func hideLoadingIndicator() {
        invokedHideLoadingIndicator = true
        invokedHideLoadingIndicatorCount += 1
    }

    var invokedShowError = false
    var invokedShowErrorCount = 0
    var invokedShowErrorParameters: (title: String, message: String, buttonTitle: String)?
    var invokedShowErrorParametersList = [(title: String, message: String, buttonTitle: String)]()
    var shouldInvokeShowErrorCompletion = false

    func showError(title: String, message: String, buttonTitle: String, completion: @escaping () -> ()) {
        invokedShowError = true
        invokedShowErrorCount += 1
        invokedShowErrorParameters = (title, message, buttonTitle)
        invokedShowErrorParametersList.append((title, message, buttonTitle))
        if shouldInvokeShowErrorCompletion {
            completion()
        }
    }
}
