//
//  FlightsViewModelTest.swift
//  OpenSkyTests
//
//  Created by Emre Alpago on 9.12.2024.
//

import XCTest
@testable import OpenSky

final class FlightsViewModelTest: XCTest {
    private var viewModel: FlightsViewModel!
    private var view: MockFlightsViewController!
    private var networkManager: MockNetworkManager!

    override func setUp() {
        super.setUp()
        view = .init()
        viewModel = .init(view: view)
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_viewDidLoad() {
        XCTAssertFalse(view.invokedSetupUI)
        XCTAssertFalse(view.invokedSetupPickerView)
        XCTAssertFalse(view.invokedAddAnnotationsToMap)
        XCTAssertFalse(networkManager.invokedRequest)
        XCTAssertEqual(networkManager.invokedRequestCount, 0)

        viewModel.viewDidLoad()

        XCTAssertTrue(view.invokedSetupUI)
        XCTAssertTrue(view.invokedSetupPickerView)
        XCTAssertTrue(networkManager.invokedRequest)
        XCTAssertEqual(networkManager.invokedRequestCount, 1)
        XCTAssertTrue(view.invokedAddAnnotationsToMap)
    }

    func test_showFlightsButtonTapped() {
        XCTAssertFalse(view.invokedAddAnnotationsToMap)

        viewModel.showFlightsButtonTapped()

        XCTAssertTrue(view.invokedAddAnnotationsToMap)
    }

    func test_filterCountriesButtonTapped() {
        XCTAssertFalse(view.invokedShowPickerView)

        viewModel.filterCountriesButtonTapped()

        XCTAssertTrue(view.invokedShowPickerView)
    }

    func test_pickerCancelButtonTapped() {
        XCTAssertFalse(view.invokedRemoveFromSuperview)

        viewModel.pickerCancelButtonTapped()

        XCTAssertTrue(view.invokedRemoveFromSuperview)
    }

    func test_pickerDoneButtonTapped() {
        XCTAssertFalse(view.invokedRemoveFromSuperview)

        viewModel.pickerCancelButtonTapped()

        XCTAssertTrue(view.invokedRemoveFromSuperview)
    }
}
