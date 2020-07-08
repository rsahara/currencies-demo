//
//  ViewController.swift
//  CurrenciesApp
//
//  Created by Sahara Runo on 2020/07/08.
//  Copyright © 2020 Runo Sahara. All rights reserved.
//

import UIKit
import CurrencyLayerAPI
import Currencies

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red

//        print(try? Currencies.default.rates(source: "JPY"))
//        let api = CurrencyLayerAPI(token: "e5cfa59531b0af65d4cc99ebbd6c7822")
//        api.rates().done { data in
//            print(data)
//        }
//        .catch { error in
//            print(error.localizedDescription)
//        }
    }
}
