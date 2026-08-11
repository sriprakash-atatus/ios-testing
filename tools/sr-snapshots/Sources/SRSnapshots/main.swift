/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the licence header.

import ArgumentParser
import SRSnapshotsCore

internal struct RootCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "CLI tool for managing Session Replay's snapshot files.",
        subcommands: [
            PushSnapshotsCommand.self,
            PullSnapshotsCommand.self,
        ]
    )
}

RootCommand.main()
