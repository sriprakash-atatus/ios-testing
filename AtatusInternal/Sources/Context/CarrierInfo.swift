/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Carrier details specific to cellular radio access.
public struct CarrierInfo: Codable, Equatable {
    // swiftlint:disable identifier_name
    public enum RadioAccessTechnology: String, Codable, CaseIterable {
        case GPRS
        case Edge
        case WCDMA
        case HSDPA
        case HSUPA
        case CDMA1x
        case CDMAEVDORev0
        case CDMAEVDORevA
        case CDMAEVDORevB
        case eHRPD
        case LTE
        case unknown
    }
    // swiftlint:enable identifier_name

    /// The name of the user’s home cellular service provider.
    public let carrierName: String?
    /// The ISO country code for the user’s cellular service provider.
    public let carrierISOCountryCode: String?
    /// Indicates if the carrier allows making VoIP calls on its network.
    public let carrierAllowsVOIP: Bool
    /// The radio access technology used for cellular connection.
    public let radioAccessTechnology: RadioAccessTechnology

    public init(
        carrierName: String?,
        carrierISOCountryCode: String?,
        carrierAllowsVOIP: Bool,
        radioAccessTechnology: RadioAccessTechnology
    ) {
        self.carrierName = carrierName
        self.carrierISOCountryCode = carrierISOCountryCode
        self.carrierAllowsVOIP = carrierAllowsVOIP
        self.radioAccessTechnology = radioAccessTechnology
    }
}
