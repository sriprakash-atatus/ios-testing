/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import Foundation

/// Possible values for the Data Tracking Consent given by the user of the app.
///
/// This value should be used to grant the permission for Atatus SDK to store data collected in
/// Logging, Tracing or RUM and upload it to Atatus servers.
public enum TrackingConsent: Codable {
    /// The permission to persist and send data to the Atatus servers was granted.
    /// Any previously stored pending data will be marked as ready for sent.
    case granted
    /// Any previously stored pending data will be deleted and all Logging, RUM and Tracing events will
    /// be dropped from now on, without persisting it in any way.
    case notGranted
    /// All Logging, RUM and Tracing events will be persisted in an intermediate location and will be pending there
    /// until `.granted` or `.notGranted` consent value is set.
    /// Based on the next consent value, intermediate data will be send to Atatus or deleted.
    case pending
}
