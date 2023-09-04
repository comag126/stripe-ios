//
//  AddPaymentMethodViewModel.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 8/23/23.
//

import Combine
import Foundation
@_spi(STP) import StripeUICore

class AddPaymentMethodViewModel: ObservableObject {
    let intent: Intent
    let configuration: PaymentSheet.Configuration

    @Published var paymentMethodTypeSelectorViewModel: PaymentMethodTypeSelectorViewModel
    @Published var linkAccount: PaymentSheetLinkAccount? = LinkAccountContext.shared.account
    @Published var overrideBuyButtonBehavior: OverrideableBuyButtonBehavior?
    @Published var overrideCallToAction: ConfirmButton.CallToActionType?
    @Published var paymentMethodFormElement: PaymentMethodElement!
    @Published var usBankAccountFormElement: USBankAccountPaymentMethodElement?

    var paymentOption: PaymentOption? {
        if let linkEnabledElement = paymentMethodFormElement as? LinkEnabledPaymentMethodElement {
            return linkEnabledElement.makePaymentOption()
        }

        let params = IntentConfirmParams(type: selectedPaymentMethodType)
        params.setDefaultBillingDetailsIfNecessary(for: configuration)
        if let params = paymentMethodFormElement.updateParams(params: params) {
            // TODO(yuki): Hack to support external_paypal
            if selectedPaymentMethodType == .externalPayPal {
                return .externalPayPal(confirmParams: params)
            }
            return .new(confirmParams: params)
        }
        return nil
    }

    private var subscriptions = Set<AnyCancellable>()

    init(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        previousCustomerInput: IntentConfirmParams? = nil
    ) {
        self.intent = intent
        self.configuration = configuration
        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration,
            logAvailability: true
        )
        paymentMethodTypeSelectorViewModel = PaymentMethodTypeSelectorViewModel(
            paymentMethodTypes: paymentMethodTypes,
            initialPaymentMethodType: previousCustomerInput?.paymentMethodType
        )
        paymentMethodFormElement = makeElement(
            for: paymentMethodTypeSelectorViewModel.selected,
            previousCustomerInput: previousCustomerInput
        )

        // We are keeping usBankAccountInfo in memory to preserve state
        // if the user switches payment method types
        usBankAccountFormElement = makeElement(
            for: .USBankAccount,
            previousCustomerInput: previousCustomerInput
        ) as? USBankAccountPaymentMethodElement

        bind()
    }

    private func bind() {
        paymentMethodTypeSelectorViewModel.$selected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedPaymentMethodType in
                guard let self = self else { return }

                if selectedPaymentMethodType == .USBankAccount {
                    self.paymentMethodFormElement = self.usBankAccountFormElement
                } else {
                    self.paymentMethodFormElement = self.makeElement(for: selectedPaymentMethodType)
                }
            }
            .store(in: &subscriptions)

        $linkAccount
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.paymentMethodFormElement = self.makeElement(for: self.paymentMethodTypeSelectorViewModel.selected)
            }
            .store(in: &subscriptions)
    }

    private func makeElement(
        for type: PaymentSheet.PaymentMethodType,
        previousCustomerInput: IntentConfirmParams? = nil
    ) -> PaymentMethodElement {
        let offerSaveToLinkWhenSupported = true// delegate?.shouldOfferLinkSignup(self) ?? false

        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(configuration),
            paymentMethod: type,
            previousCustomerInput: previousCustomerInput,
            offerSaveToLinkWhenSupported: offerSaveToLinkWhenSupported,
            linkAccount: linkAccount
        ).make()
        return formElement
    }
}
