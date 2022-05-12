//
//  SetupKeysEndpoint.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 21.12.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Authentication
import ProtonCore_DataModel
import ProtonCore_Networking

extension AuthService {
    struct CreateAddressKeysEndpointResponse: Codable {
        let code: Int
        let key: Key
    }

    struct CreateAddressKeyEndpoint: Request {
        let addressID: String
        let privateKey: String
        let signedKeyList: [String: Any]
        let primary: Bool

        var path: String {
            return "/keys"
        }
        var method: HTTPMethod {
            return .post            
        }

        var isAuth: Bool {
            return true
        }

        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            return self.auth
        }

        var parameters: [String: Any]? {
            let address: [String: Any] = [
                "AddressID": addressID,
                "PrivateKey": privateKey,
                "Primary": primary ? 1 : 0,
                "SignedKeyList": signedKeyList
            ]

            return address
        }
    }
}
