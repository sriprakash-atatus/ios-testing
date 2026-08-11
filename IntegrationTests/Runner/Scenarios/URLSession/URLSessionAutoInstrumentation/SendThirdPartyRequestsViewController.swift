/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the licence
// header.

import Foundation
import UIKit
import AtatusCore

internal class SendThirdPartyRequestsViewController: UIViewController {
    private var testScenario: URLSessionBaseScenario!
    private lazy var session = testScenario.getURLSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.testScenario = (appConfiguration.testScenario as! URLSessionBaseScenario)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        callThirdPartyURL()
        callThirdPartyURLRequest()
    }

    private func callThirdPartyURL() {
        let task = session.dataTask(with: testScenario.thirdPartyURL)
        task.resume()
    }

    private func callThirdPartyURLRequest() {
        let task = session.dataTask(with: testScenario.thirdPartyRequest)
        task.resume()
    }
}
