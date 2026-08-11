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

internal class SendFirstPartyRequestsViewController: UIViewController {
    private var testScenario: URLSessionBaseScenario!
    private lazy var session = testScenario.getURLSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        testScenario = (appConfiguration.testScenario as! URLSessionBaseScenario)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        callSuccessfulFirstPartyURL()
        callSuccessfulFirstPartyURLRequest()
        callBadFirstPartyURL()
    }

    private func callSuccessfulFirstPartyURL() {
        let task = session.dataTask(with: testScenario.customGETResourceURL) { _, _, error in
            assert(error == nil)
        }
        task.resume()
    }

    private func callSuccessfulFirstPartyURLRequest() {
        let task = session.dataTask(with: testScenario.customPOSTRequest) { _, _, error in
            assert(error == nil)
        }
        task.resume()
    }

    private func callBadFirstPartyURL() {
        let task = session.dataTask(with: testScenario.badResourceURL)
        task.resume()
    }
}
