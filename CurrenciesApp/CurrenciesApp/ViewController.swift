//
//  ViewController.swift
//  CurrenciesApp
//
//  Created by Sahara Runo on 2020/07/08.
//  Copyright © 2020 Runo Sahara. All rights reserved.
//

import UIKit
import Currencies

class ViewModel {
    var sourceCurrencyCode: String = "USD"
    var amount: Double = 100.0
    var rates = [String: Double]()
    var sortedCurrencyCodes: [String] {
        return _sortedCurrencyCodes
    }

    // Commits view model to model, ask the UI to update (no data binding).
    func commit(_ viewController: ViewController?) throws {
        rates = try Currencies.default.rates(sourceCurrencyCode: sourceCurrencyCode)
        _sortedCurrencyCodes = rates.keys.sorted()
        viewController?.update(with: self)
    }

    // Currency codes sorted by code.
    private var _sortedCurrencyCodes = [String]()
}

class ViewController: UIViewController {
    private lazy var viewModel = ViewModel()
    private lazy var textField = UITextField()
    private lazy var button = UIButton()
    private lazy var tableView = UITableView()
}

extension ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        var constraints = [NSLayoutConstraint]()

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .systemGray6
        textField.textAlignment = .center
        textField.returnKeyType = .done
        textField.keyboardType = .numbersAndPunctuation
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        textField.text = "\(viewModel.amount)"
        view.addSubview(textField)
        constraints += [
            textField.topAnchor.constraint(equalTo: view.topAnchor, constant: 50.0),
            textField.heightAnchor.constraint(equalToConstant: 50.0),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: button.leadingAnchor),
        ]

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(touchButton), for: .touchUpInside)
        view.addSubview(button)
        constraints += [
            button.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 200.0),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        constraints += [
            tableView.topAnchor.constraint(equalTo: textField.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)

        // Sync with the initial values
        try! viewModel.commit(self)

        // Try to update the models. Sync the UI if there were updates.
        Currencies.default.updateRates().done(on: .main) { [weak self] in
            guard let self = self else { return }
            let viewModel = self.viewModel
            viewModel.rates = try Currencies.default.rates(sourceCurrencyCode: viewModel.sourceCurrencyCode)
            try viewModel.commit(self)
        }.catch { error in
            print("\(error.localizedDescription)")
        }
    }
}

// MARK: - UI updates

extension ViewController {
    func update(with viewModel: ViewModel) {
        button.setTitle("\(viewModel.sourceCurrencyCode) (click to change)", for: .normal)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rates.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let currency = viewModel.sortedCurrencyCodes[indexPath.row]
        let rate = viewModel.rates[currency] ?? 0.0
        let exchangedAmount = viewModel.amount * rate
        cell.textLabel?.text = "\(exchangedAmount) \(currency) (rate: \(rate))"
        return cell
    }
}

// MARK: - UI events

extension ViewController {
    @objc func textFieldChanged() {
        guard let text = textField.text, let amount = Double(text) else { return }
        viewModel.amount = amount
        try! viewModel.commit(self)
    }

    @objc func touchButton() {
        let selectCurrencyViewController = SelectCurrencyViewController()
        selectCurrencyViewController.delegate = self
        present(selectCurrencyViewController, animated: true, completion: nil)
    }
}

extension ViewController: SelectCurrencyViewControllerDelegate {
    func didSelectCurrency(viewController: SelectCurrencyViewController, currencyCode: String) {
        viewModel.sourceCurrencyCode = currencyCode
        try! viewModel.commit(self)
        viewController.dismiss(animated: true, completion: nil)
    }
}
