//
//  PaymentMethodTypeCarouselView.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 8/29/23.
//

import SwiftUI

struct PaymentMethodTypeCarouselView: View {
    static let paymentMethodLogoSize: CGSize = CGSize(width: UIView.noIntrinsicMetric, height: 12)
    static let cellHeight: CGFloat = 52
    static let minInteritemSpacing: CGFloat = 12

    @ObservedObject var paymentMethodTypeViewModel: PaymentMethodTypeSelectorViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(paymentMethodTypeViewModel.paymentMethodTypes) { type in
                    VStack {
                        Text(type.displayName)
                    }
                }
            }
        }
    }
}

struct PaymentMethodTypeCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = PaymentMethodTypeSelectorViewModel(
            paymentMethodTypes:
                [
                    .card,
                    .USBankAccount,
                    .dynamic("klarna"),
                    .dynamic("afterpay_clearpay"),
                ],
            initialPaymentMethodType: nil
        )
        PaymentMethodTypeCarouselView(paymentMethodTypeViewModel: viewModel)
    }
}

extension PaymentSheet.PaymentMethodType: Identifiable {
    typealias ID = String

    var id: String { self.identifier }
}
