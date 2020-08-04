//
//  ApiDataProvider.swift
//  TV Shows
//
//  Created by Dorota Piačeková on 04/08/2020.
//  Copyright © 2020 Dorota Piačeková. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import ETPersistentValue

/// Base DataProvider to be extended with a protocol for every screen/module
final class ApiDataProvider {
	
	// MARK: - Public
	
	/**
	Generic function which does an API call to specified endpoint.

	- Parameter endpoint: The endpoint the call is being sent to.
	- Parameter body: Optional body of the request. Should be left `nil` for HTTP method `get`.
	
	- Returns: A Promise which is either fulfilled with an object of specified type `<ResultType>` or rejected with error.
	*/
	func load<ResultType: Decodable, BodyType: Encodable>(from endpoint: Endpoint, body: BodyType? = nil) -> Promise<ResultType> {
		Promise { resolver in
			let method = endpoint.method
			let url = endpoint.url
			let headers = endpoint.headers
			let params = body?.dictionary

			AF.request(url, method: method, parameters: method == .get ? nil : params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
				switch response.result {
				case .success(let data):
					guard let data = data as? ResultType else {
						return resolver.reject(AFError.responseValidationFailed(reason: .dataFileNil))
					}
					resolver.fulfill(data)
				case .failure(let error):
					resolver.reject(error)
				}
			}
		}
    }
}

// MARK: - RequestAdapter

extension ApiDataProvider: RequestAdapter {
	func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
		if let token = PersistentString(account: PersistentKey.accessToken).value {
			var urlRequest = urlRequest
			urlRequest.headers.add(.authorization(token))
			completion(.success(urlRequest))
		}
	}
}