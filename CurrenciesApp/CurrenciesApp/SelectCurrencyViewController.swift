//
//  SelectCurrencyViewController.swift
//  CurrenciesApp
//
//  Created by Sahara Runo on 2020/07/08.
//  Copyright © 2020 Runo Sahara. All rights reserved.
//

import UIKit
import Currencies

protocol SelectCurrencyViewControllerDelegate: AnyObject {
    func didSelectCurrency(viewController: SelectCurrencyViewController, currencyCode: String)
}

class SelectCurrencyViewController: UIViewController {
    public weak var delegate: SelectCurrencyViewControllerDelegate?
    public required init?(coder aDecoder: NSCoder) { fatalError() }
    public init() {
        currencyCodes = []
        super.init(nibName: nil, bundle: nil)
    }

    private var currencyCodes: [String]
    private lazy var tableView = UITableView()
}

extension SelectCurrencyViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        var constraints = [NSLayoutConstraint]()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        constraints += [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]

        NSLayoutConstraint.activate(constraints)

        currencyCodes = try! Currencies.default.currencyCodes()
        Currencies.default.updateCurrencyCodes().done(on: .main) { [weak self] in
            guard let self = self else { return }
            self.currencyCodes = try! Currencies.default.currencyCodes()
            self.tableView.reloadData()
        }.catch { error in
            print("\(error.localizedDescription)")
        }
    }
}

extension SelectCurrencyViewController: UITableViewDataSource {
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        currencyCodes.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = currencyCodes[indexPath.row]
        return cell
    }
}

extension SelectCurrencyViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectCurrency(viewController: self, currencyCode: currencyCodes[indexPath.row])
    }
}
