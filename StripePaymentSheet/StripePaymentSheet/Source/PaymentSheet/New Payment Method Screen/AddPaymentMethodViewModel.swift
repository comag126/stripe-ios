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
    let isLinkEnabled: Bool

    @Published var paymentMethodTypeSelectorViewModel: PaymentMethodTypeSelectorViewModel
    @Published var linkAccount: PaymentSheetLinkAccount? = LinkAccountContext.shared.account
    @Published var paymentMethodFormElement: PaymentMethodElement!
    @Published var usBankAccountFormElement: USBankAccountPaymentMethodElement?
    @Published var paymentOption: PaymentOption?

    private var subscriptions = Set<AnyCancellable>()

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

    var shouldOfferLinkSignup: Bool {
        guard isLinkEnabled else { return false }
        return LinkAccountContext.shared.account.flatMap({ !$0.isRegistered }) ?? true
    }

    init(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        previousCustomerInput: IntentConfirmParams? = nil,
        isLinkEnabled: Bool = false
    ) {
        self.intent = intent
        self.configuration = configuration
        self.isLinkEnabled = isLinkEnabled
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

        LinkAccountContext.shared.addObserver(self, selector: #selector(linkAccountChanged(_:)))

        updatePaymentOption()

        bind()
    }

    deinit {
        LinkAccountContext.shared.removeObserver(self)
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
                self.updatePaymentOption()
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
        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(configuration),
            paymentMethod: type,
            previousCustomerInput: previousCustomerInput,
            offerSaveToLinkWhenSupported: shouldOfferLinkSignup,
            linkAccount: linkAccount
        ).make()
        formElement.delegate = self
        return formElement
    }

    @objc
    func linkAccountChanged(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.linkAccount = notification.object as? PaymentSheetLinkAccount
        }
    }

    private func updatePaymentOption() {
        paymentOption = {
            if let linkEnabledElement = paymentMethodFormElement as? LinkEnabledPaymentMethodElement {
                return linkEnabledElement.makePaymentOption()
            }

            var params = IntentConfirmParams(type: paymentMethodTypeSelectorViewModel.selected)
            params = paymentMethodFormElement.applyDefaults(params: params)
            if let params = paymentMethodFormElement.updateParams(params: params) {
                return .new(confirmParams: params)
            }
            return nil
        }()
    }
}

extension AddPaymentMethodViewModel: ElementDelegate {
    func continueToNextField(element: Element) {
        updatePaymentOption()
    }

    func didUpdate(element: Element) {
        updatePaymentOption()
    }
}
