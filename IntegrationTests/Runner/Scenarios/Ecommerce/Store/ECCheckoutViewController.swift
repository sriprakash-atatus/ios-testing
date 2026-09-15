/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Checkout screens of the store in `AtatusEcommerceScenario` — the delivery address, then
// payment. Payment is the one step of the funnel that fails on purpose — the backend declines the
// first authorisation with a 502, so the run captures a genuinely failed request alongside the
// successful ones. Nothing about the failure is reported by hand; the agent sees the response like
// it sees every other.

import UIKit

// MARK: - Address

/// The delivery address form. Opens filled in, so "Deliver Here" goes straight through.
final class ECAddressViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI

    private let nameField = UITextField()
    private let phoneField = UITextField()
    private let pincodeField = UITextField()
    private let lineField = UITextField()
    private let cityField = UITextField()
    private let typeControl = UISegmentedControl(items: ["Home", "Work"])
    private let errorLabel = ECStyle.label("", style: .footnote, color: .systemRed)
    private lazy var deliverButton = ECStyle.primaryButton("Deliver Here", target: self, action: #selector(didTapDeliverHere))
    private var isSaving = false
    private var visit = 0

    init(store: ECStore, api: ECStoreAPI) {
        self.store = store
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Delivery Address"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = ECStyle.pageBackground
        view.accessibilityIdentifier = "Delivery Address"

        let address = store.address
        configure(nameField, placeholder: "Full Name (Required)", text: address.name, contentType: .name, keyboard: .default)
        configure(phoneField, placeholder: "Phone number (Required)", text: address.phone, contentType: .telephoneNumber, keyboard: .phonePad)
        configure(pincodeField, placeholder: "Pincode (Required)", text: address.pincode, contentType: .postalCode, keyboard: .numberPad)
        configure(lineField, placeholder: "House No., Building Name, Area (Required)", text: address.line, contentType: .fullStreetAddress, keyboard: .default)
        configure(cityField, placeholder: "City (Required)", text: address.city, contentType: .addressCity, keyboard: .default)

        typeControl.selectedSegmentIndex = address.type == "Work" ? 1 : 0
        typeControl.accessibilityIdentifier = "Address Type"
        errorLabel.isHidden = true

        let form = ECStyle.card([
            ECStyle.sectionHeader("Contact details"),
            nameField,
            phoneField,
            ECStyle.sectionHeader("Address"),
            pincodeField,
            lineField,
            cityField,
            ECStyle.label("Type of address", style: .subheadline, color: .secondaryLabel),
            typeControl,
            errorLabel
        ], spacing: 12)

        let bar = ECStyle.bottomBar(in: view, arrangedSubviews: [deliverButton])
        ECStyle.scrollingColumn(in: view, arrangedSubviews: [ECStyle.checkoutSteps(current: 1), form], above: bar)
        hideKeyboardWhenTapOutside()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        guard visit == 1 else {
            return
        }
        ECAutoPilot.step(after: 2.5) { [weak self] in self?.didTapDeliverHere() }
    }

    private func configure(_ field: UITextField, placeholder: String, text: String, contentType: UITextContentType, keyboard: UIKeyboardType) {
        field.placeholder = placeholder
        field.text = text
        field.textContentType = contentType
        field.keyboardType = keyboard
        field.borderStyle = .roundedRect
        field.accessibilityIdentifier = placeholder
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    @objc
    private func didTapDeliverHere() {
        guard !isSaving else {
            return
        }
        view.endEditing(true)

        let address = ECAddress(
            name: nameField.text ?? "",
            phone: (phoneField.text ?? "").trimmingCharacters(in: .whitespaces),
            pincode: (pincodeField.text ?? "").trimmingCharacters(in: .whitespaces),
            line: lineField.text ?? "",
            city: cityField.text ?? "",
            type: typeControl.titleForSegment(at: typeControl.selectedSegmentIndex) ?? "Home"
        )
        if let error = address.validationError {
            errorLabel.text = error
            errorLabel.isHidden = false
            return
        }
        errorLabel.isHidden = true

        isSaving = true
        deliverButton.isEnabled = false
        store.address = address

        api.saveAddress(address) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.isSaving = false
            self.deliverButton.isEnabled = true
            self.flow?.showPayment()
        }
    }
}

// MARK: - Payment

/// Takes payment for the cart — UPI, card, net banking or cash on delivery — retries once after the
/// first authorisation fails, then creates the order.
final class ECCheckoutViewController: UIViewController, ECStoreScreen {
    private let store: ECStore
    private let api: ECStoreAPI
    private let optionsStack = UIStackView()
    private let statusLabel = ECStyle.label("", style: .footnote, color: .secondaryLabel)
    private lazy var payButton = ECStyle.primaryButton("Pay", target: self, action: #selector(didTapPay))
    private var attempt = 0
    private var visit = 0

    init(store: ECStore, api: ECStoreAPI) {
        self.store = store
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used — the store builds its screens in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Payment"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = ECStyle.pageBackground
        view.accessibilityIdentifier = "Checkout"

        optionsStack.axis = .vertical
        optionsStack.spacing = 4

        let address = store.address
        let deliverTo = ECStyle.card([
            ECStyle.label("Deliver to", style: .subheadline, color: .secondaryLabel),
            ECStyle.label("\(address.name)  ·  \(address.type.uppercased())", style: .headline),
            ECStyle.label(address.summary, style: .subheadline),
            ECStyle.label(address.phone, style: .subheadline, color: .secondaryLabel)
        ], spacing: 4)

        var summaryRows: [UIView] = [
            ECStyle.amountRow("Price (\(store.itemCount) item\(store.itemCount == 1 ? "" : "s"))", ECMoney.format(store.subtotal)),
            ECStyle.amountRow("Delivery Charges", store.deliveryFee == 0 ? "FREE" : ECMoney.format(store.deliveryFee)),
            ECStyle.separator(),
            ECStyle.amountRow("Amount Payable", ECMoney.format(store.total), emphasised: true)
        ]
        if store.discount > 0 {
            summaryRows.append(ECStyle.label("You save \(ECMoney.format(store.discount)) on this order", style: .subheadline, color: ECStyle.offerGreen))
        }

        let payments = ECStyle.card([ECStyle.sectionHeader("Payment options"), optionsStack, statusLabel], spacing: 8)
        let bar = ECStyle.bottomBar(in: view, arrangedSubviews: [payButton])
        ECStyle.scrollingColumn(
            in: view,
            arrangedSubviews: [ECStyle.checkoutSteps(current: 2), deliverTo, payments, ECStyle.card(summaryRows, spacing: 10)],
            above: bar
        )

        renderOptions()
        updatePayButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        visit += 1
        guard visit == 1 else {
            return
        }
        // Looks at card, settles on UPI, then pays — the replay shows the options being weighed.
        ECAutoPilot.step(after: 1.2) { [weak self] in self?.select(.card) }
        ECAutoPilot.step(after: 2.4) { [weak self] in self?.select(.upi) }
        ECAutoPilot.step(after: 3.6) { [weak self] in self?.didTapPay() }
    }

    // MARK: - Options

    private func renderOptions() {
        let rows = ECPaymentMethod.allCases.enumerated().map { index, method -> UIView in
            let isSelected = method == store.paymentMethod

            let radio = UIImageView(image: UIImage(systemName: isSelected ? "largecircle.fill.circle" : "circle"))
            radio.tintColor = isSelected ? ECStyle.brandBlue : .secondaryLabel
            radio.setContentHuggingPriority(.required, for: .horizontal)

            let text = UIStackView(arrangedSubviews: [
                ECStyle.label(method.title, style: .body),
                ECStyle.label(method.detail, style: .caption1, color: .secondaryLabel)
            ])
            text.axis = .vertical
            text.spacing = 2

            let icon = UIImageView(image: UIImage(systemName: method.icon))
            icon.tintColor = .secondaryLabel
            icon.setContentHuggingPriority(.required, for: .horizontal)

            let row = UIStackView(arrangedSubviews: [radio, text, icon])
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .center

            let tile = ECTapTile(content: row, identifier: "payment-\(method.rawValue)", insets: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
            tile.tag = index
            tile.addTarget(self, action: #selector(didSelectPaymentOption(_:)), for: .touchUpInside)
            return tile
        }
        ECStyle.replaceArrangedSubviews(of: optionsStack, with: rows)
    }

    private func updatePayButton() {
        let title = store.paymentMethod.requiresAuthorization ? "Pay \(ECMoney.format(store.total))" : "Place Order"
        payButton.setTitle(title, for: .normal)
        payButton.accessibilityIdentifier = title
    }

    @objc
    private func didSelectPaymentOption(_ sender: UIControl) {
        guard ECPaymentMethod.allCases.indices.contains(sender.tag) else {
            return
        }
        select(ECPaymentMethod.allCases[sender.tag])
    }

    private func select(_ method: ECPaymentMethod) {
        // Not while a payment is in flight: the order would be placed with a method nobody paid by.
        guard payButton.isEnabled else {
            return
        }
        store.paymentMethod = method
        renderOptions()
        updatePayButton()
    }

    // MARK: - Payment

    @objc
    private func didTapPay() {
        guard payButton.isEnabled, !store.isEmpty else {
            return
        }
        payButton.isEnabled = false
        statusLabel.textColor = .secondaryLabel

        let method = store.paymentMethod
        guard method.requiresAuthorization else {
            statusLabel.text = "Placing your order…"
            createOrder()
            return
        }

        attempt += 1
        statusLabel.text = attempt == 1 ? "Authorising \(method.title) payment…" : "Retrying payment…"

        // The backend declines attempt 1 with a 502 and accepts the retry, so every run captures the
        // same real failure and the same recovery on both sides of the trace.
        api.authorizePayment(amount: store.total, method: method, attempt: attempt) { [weak self] succeeded in
            guard let self = self else {
                return
            }
            if succeeded {
                self.statusLabel.text = "Payment authorised — placing your order…"
                self.createOrder()
            } else {
                self.authorizationFailed()
            }
        }
    }

    private func authorizationFailed() {
        statusLabel.text = "Payment could not be authorised — please retry"
        statusLabel.textColor = .systemRed
        payButton.setTitle("Retry Payment", for: .normal)
        payButton.accessibilityIdentifier = "Retry Payment"
        payButton.isEnabled = true

        // A shopper would try again, so the funnel does too.
        ECAutoPilot.step(after: 2.5) { [weak self] in self?.didTapPay() }
    }

    private func createOrder() {
        api.placeOrder(lines: store.lines, address: store.address, paymentMethod: store.paymentMethod) { [weak self] receipt in
            guard let self = self else {
                return
            }
            self.store.completeOrder(reference: receipt?.reference ?? "ORD-PENDING", deliveryDays: receipt?.deliveryDays ?? 4)
            self.flow?.showOrderConfirmation()
        }
    }
}
