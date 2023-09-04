//
//  PaymentMethodTypeSelectorViewModel.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 8/23/23.
//

import Combine
import Foundation
@_spi(STP) import StripeCore

class PaymentMethodTypeSelectorViewModel: ObservableObject {
    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    @Published var selected: PaymentSheet.PaymentMethodType

    // This property is only used for logging purposes.
    let isPaymentSheet: Bool

    var subscribers = Set<AnyCancellable>()

    var selectedItemIndex: Int { paymentMethodTypes.firstIndex(of: selected) ?? 0 }

    init(
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        initialPaymentMethodType: PaymentSheet.PaymentMethodType? = nil,
        isPaymentSheet: Bool = false
    ) {
        self.paymentMethodTypes = paymentMethodTypes
        let selectedItemIndex: Int = {
            if let initialPaymentMethodType = initialPaymentMethodType {
                return paymentMethodTypes.firstIndex(of: initialPaymentMethodType) ?? 0
            } else {
                return 0
            }
        }()

        self.selected = paymentMethodTypes[selectedItemIndex]
        self.isPaymentSheet = isPaymentSheet

        self.$selected
            .sink { type in
                // Only log this event when the selector is being used by PaymentSheet.
                if isPaymentSheet {
                    STPAnalyticsClient.sharedClient.logPaymentSheetEvent(
                        event: .paymentSheetCarouselPaymentMethodTapped,
                        paymentMethodTypeAnalyticsValue: type.identifier
                    )
                }
            }
            .store(in: &subscribers)
    }

    func selectItem(at index: Int) {
        guard index >= 0 && index < paymentMethodTypes.count else {
            assertionFailure("Index out of bounds: \(index)")
            return
        }

        selected = paymentMethodTypes[index]
    }
}
