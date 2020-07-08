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
    // Gets a list of currency codes locally.
    func currencyCodes() throws -> [String]
    // Updates the list of currency codes from the server.
    func updateCurrencyCodes() -> Promise<Void>
    // Gets the list of exchange rates for the given currency code, calculated locally.
    func rates(sourceCurrencyCode: String) throws -> [String: Double]
    // Updates the list of exchange rates from the server.
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
    public func currencyCodes() throws -> [String] {
        let context = self.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Rate> = Rate.fetchRequest()
        let rates = try context.fetch(fetchRequest)
        var result = rates.compactMap { rate in rate.code }
        result.append("USD")
        return result
    }

    public func updateCurrencyCodes() -> Promise<Void> {
        // Use the rates data.
        updateRates()
    }

    public func rates(sourceCurrencyCode: String) throws -> [String: Double] {
        let context = self.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Rate> = Rate.fetchRequest()
        let rates = try context.fetch(fetchRequest)
        var rateMap: [String: Double] = ["USD": 1.0]
        for rate in rates {
            rateMap[rate.code!] = rate.rate
        }
        guard let usdToSourceRate = rateMap[sourceCurrencyCode] else {
            throw CurrenciesError("Unknown currency code")
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
        return api.rates().then { [weak self] rates in
            self?.saveModels(rates: rates, updateTime: now) ?? .value(())
        }
    }
}

private extension Currencies {
    private func saveModels(rates: [String: Double], updateTime: Date) -> Promise<Void> {
        self.persistentContainer.performInBackground { (context: NSManagedObjectContext) -> () in
            let fetchRequest: NSFetchRequest<Rate> = Rate.fetchRequest()
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
            UserDefaults.standard.setValue(updateTime, forKey: "lastUpdateRates")
        }
    }
}

private extension NSPersistentContainer {
    func performInBackground<T>(body: @escaping (NSManagedObjectContext) throws -> T) -> Promise<T> {
        let (promise, resolver) = Promise<T>.pending()
        performBackgroundTask { context in
            let result: T
            do {
                result = try body(context)
            }
            catch {
                resolver.reject(error)
                return
            }
            resolver.fulfill(result)
        }
        return promise
    }
}
