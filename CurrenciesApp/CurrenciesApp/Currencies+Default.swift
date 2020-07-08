//
//  Currencies+Default.swift
//  CurrenciesApp
//
//  Created by Sahara Runo on 2020/07/08.
//  Copyright © 2020 Runo Sahara. All rights reserved.
//

import Foundation
import Currencies
import CurrencyLayerAPI

extension Currencies {
    static let `default`: Currencies = {
        let api = CurrencyLayerAPI(token: "e5cfa59531b0af65d4cc99ebbd6c7822")
        return try! Currencies(api: api)
    }()
}
