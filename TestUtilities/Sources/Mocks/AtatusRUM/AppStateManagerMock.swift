/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; rebranded the licence header.

import Foundation
import AtatusInternal
@testable import AtatusRUM

/// Mock of the AppState manager.
public final class AppStateManagerMock: AppStateManaging {
    public var previousAppStateInfo: AppStateInfo?
    public var currentAppStateInfo: AppStateInfo = .mockAny()
    public var shouldDeferPreviousAppStateInfoCallback: Bool = false

    private var previousAppStateInfoCompletion: ((AppStateInfo?) -> Void)?

    public func deleteAppState() {}
    public func updateAppState(state: AppState) {}
    public func previousAppStateInfo(completion: @escaping (AtatusRUM.AppStateInfo?) -> Void) {
        if shouldDeferPreviousAppStateInfoCallback {
            previousAppStateInfoCompletion = completion
        } else {
            completion(previousAppStateInfo)
        }
    }
    public func currentAppStateInfo(completion: @escaping (AppStateInfo) -> Void) {
        completion(currentAppStateInfo)
    }
    public func storeCurrentAppState() {}

    public func completePreviousAppStateInfo() {
        let completion = previousAppStateInfoCompletion
        previousAppStateInfoCompletion = nil
        completion?(previousAppStateInfo)
    }
}
