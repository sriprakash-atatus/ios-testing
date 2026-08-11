/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

internal func pullSnapshots(to localRepo: LocalRepo, from remoteRepo: RemoteRepo) throws {
    try remoteRepo.pull()

    // Determine new files to pull from remote repo:
    let newRemoteFilesWithPointers: [(FileLocation, Pointer)] = try localRepo
        // 1. Read all pointers from "pointer files"
        .readPointers()
        // 2. Map each pointer into "remote file" location
        .map { pointer in (remoteRepo.remoteFileLocation(for: pointer), pointer) }

    print("⬇️   Pulling \(newRemoteFilesWithPointers.count) file(s)")

    try localRepo.deleteLocalFiles()
    for (remoteFile, pointer) in newRemoteFilesWithPointers {
        // Copy each new "remote file" to "local file" location determined by pointer
        let localFile = localRepo.localFileLocation(for: pointer)
        try remoteFile.copy(to: localFile)
    }
}
