//
//  CurrencyLayerAPI.swift
//  CurrencyLayerAPI
//
//  Created by Sahara Runo on 2020/07/08.
//  Copyright © 2020 Runo Sahara. All rights reserved.
//

import Foundation
import PromiseKit

public class CurrencyLayerAPI {
    public init(token: String) {
        self.token = token
    }

    private let token: String
    private let baseURLString = "https://api.currencylayer.com/"
}
