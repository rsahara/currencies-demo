//
//  CurrencyLayerAPI.swift
//  CurrencyLayerAPI
//
//  Created by Sahara Runo on 2020/07/08.
//  Copyright © 2020 Runo Sahara. All rights reserved.
//

import Foundation
import PromiseKit

// For tests do something like `class CurrenciesMock: CurrenciesProtocol`
public protocol CurrencyLayerAPIProtocol {
//    func currencies() -> Promise<[String: String]>
    func rates() -> Promise<[String: Double]>
}

public class CurrencyLayerAPI {
    public init(
        token: String,
        baseURLString: String = "http://api.currencylayer.com/"
    ) {
        self.token = token
        self.baseURLString = baseURLString
    }

    private let token: String
    private let baseURLString: String
}

extension CurrencyLayerAPI: CurrencyLayerAPIProtocol {
//    public func currencies() -> Promise<[String: String]> {
//        request(endPoint: "list", params: [:]).map { root in
//            guard let currencies = root["currencies"] as? [String: String] else {
//                throw CurrencyLayerAPIError("currencies expected", type: .badResponse(root))
//            }
//            return currencies
//        }
//    }

    public func rates() -> Promise<[String: Double]> {
        request(endPoint: "live", params: [:]).map { root in
            guard let quotes = root["quotes"] as? [String: Double] else {
                throw CurrencyLayerAPIError("quotes expected", type: .badResponse(root))
            }
            return quotes
        }
    }
}

internal extension CurrencyLayerAPI {
    func request(endPoint: String, params: [String: String?]) -> Promise<[String: Any]> {
        let url: URL
        do {
            url = try makeURL(endPoint: endPoint, params: params)
        }
        catch {
            return .init(error: error)
        }
        let (promise, resolver) = Promise<[String: Any]>.pending()
        let urlRequest = URLRequest(url: url)
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            let result: [String: Any]
            do {
                result = try CurrencyLayerAPI.processResponse(data, response, error)
            }
            catch {
                resolver.reject(error)
                return
            }
            resolver.fulfill(result)
        }
        dataTask.resume()
        return promise
    }

    private static func processResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) throws -> [String: Any] {
        guard error == nil, let data = data, let response = response as? HTTPURLResponse else {
            throw CurrencyLayerAPIError("Request failed", type: .nonFatal(error))
        }
        switch response.statusCode {
        case 200..<300:
            let jsonObj = try JSONSerialization.jsonObject(with: data)
            guard let rootDict = jsonObj as? [String: Any], rootDict["success"] as? Bool ?? false else {
                throw CurrencyLayerAPIError("Request failed", type: .badResponse(jsonObj))
            }
            return rootDict
        default:
            throw CurrencyLayerAPIError("HTTP status code")
        }
    }

    private func makeURL(endPoint: String, params: [String: String?]) throws -> URL {
        guard var urlComponents = URLComponents(string: baseURLString) else {
            throw CurrencyLayerAPIError("Bad URL", type: .fatal(nil))
        }
        urlComponents.path = "/" + endPoint
        var queryItems = [URLQueryItem(name: "access_key", value: token)]
        for (name, value) in params {
            queryItems.append(URLQueryItem(name: name, value: value))
        }
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            throw CurrencyLayerAPIError("Bad URL", type: .fatal(nil))
        }
        return url
    }
}
