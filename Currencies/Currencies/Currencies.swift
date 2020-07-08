//
//  Currencies.swift
//  Currencies
//
//  Created by Sahara Runo on 2020/07/08.
//  Copyright © 2020 Runo Sahara. All rights reserved.
//

import Foundation
import PromiseKit
import CurrencyLayerAPI
import CoreData

// For tests do something like `class CurrenciesMock: CurrenciesProtocol`
public protocol CurrenciesProtocol {
    func currencies() throws -> [String]
    func updateCurrencies() -> Promise<Void>
    func rates(source: String) throws -> [String: Double]
    func updateRates() -> Promise<Void>
}

public class Currencies {
    public init(api: CurrencyLayerAPIProtocol) throws {
        self.api = api

        guard let bundle = Bundle(identifier: "jp.runo.Currencies"),
            let modelURL = bundle.url(forResource: "Currencies", withExtension: "momd"),
            let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
                throw CurrenciesError("Model initialization", type: .fatal(nil))
        }
        self.persistentContainer = NSPersistentContainer(name: "Currencies", managedObjectModel: managedObjectModel)
        var loadError: Error?
        self.persistentContainer.loadPersistentStores { (_, error) in
            if let error = error {
                loadError = error
            }
        }
        if let loadError = loadError {
            throw CurrenciesError("Model initialization", type: .fatal(loadError))
        }
    }

    private let api: CurrencyLayerAPIProtocol
    private var persistentContainer: NSPersistentContainer
}

extension Currencies: CurrenciesProtocol {
    public func currencies() throws -> [String] {
        let context = self.persistentContainer.newBackgroundContext()
        let fetchRequest = NSFetchRequest<Rate>(entityName: "Rate")
        let rates = try context.fetch(fetchRequest)
        var result = rates.compactMap { rate in rate.code }
        result.append("USD")
        return result.sorted()
    }

    public func updateCurrencies() -> Promise<Void> {
        // Use the rates data.
        updateRates()
    }

    public func rates(source: String) throws -> [String: Double] {
        let context = self.persistentContainer.newBackgroundContext()
        let fetchRequest = NSFetchRequest<Rate>(entityName: "Rate")
        let rates = try context.fetch(fetchRequest)
        var rateMap: [String: Double] = ["USD": 1.0]
        for rate in rates {
            rateMap[rate.code!] = rate.rate
        }
        guard let usdToSourceRate = rateMap[source] else {
            throw CurrenciesError("Unknown source")
        }
        let sourceToUSDRate = 1.0 / usdToSourceRate
        var result = [String: Double]()
        for (code, rate) in rateMap {
            result[code] = sourceToUSDRate * rate
        }
        return result
    }

    public func updateRates() -> Promise<Void> {
        let now = Date()
        if let lastUpdate = UserDefaults.standard.value(forKey: "lastUpdateRates") as? Date,
            Date(timeInterval: 60.0 * 30.0, since: lastUpdate) > Date() {
            return .init(error: CurrenciesError("Too frequent", type: .noUpdates))
        }
        return api.rates().done { rates in
            let context = self.persistentContainer.newBackgroundContext()
            let fetchRequest = NSFetchRequest<Rate>(entityName: "Rate")
            let models = try context.fetch(fetchRequest)
            models.forEach { model in
                context.delete(model)
            }
            for (rateCode, rate) in rates {
                guard rateCode.hasPrefix("USD"), rateCode.count == 6 else {
                    throw CurrenciesError("Unexpected data")
                }
                let code = String(rateCode.suffix(3))
                let rateModel = NSEntityDescription.insertNewObject(forEntityName: "Rate", into: context) as! Rate
                rateModel.code = code
                rateModel.rate = rate
            }
            try context.save()
            UserDefaults.standard.setValue(now, forKey: "lastUpdateRates")
        }
    }
}
