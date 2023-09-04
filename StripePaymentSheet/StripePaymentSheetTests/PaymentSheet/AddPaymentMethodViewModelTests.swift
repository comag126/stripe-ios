//
//  AddPaymentMethodViewModelTests.swift
//  StripePaymentSheetTests
//
//  Created by Eduardo Urias on 9/4/23.
//

import Foundation
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

class AddPaymentMethodViewModelTests: XCTest {
    func testCardFormIsUsed() {
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["paypal", "card", "cashApp"]))
        var config = PaymentSheet.Configuration._testValue_MostPermissive()

        var viewModel = AddPaymentMethodViewModel(intent: intent, configuration: config)
        viewModel.paymentMethodTypeSelectorViewModel.selected = .card

        // Test that viewModel.paymentMethodFormElement is a card form.
    }
}
