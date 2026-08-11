/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI

struct EpisodeListItem: View {
    let episode: Episode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(episode.name)
                .font(.headline)

            HStack {
                Text(episode.episode)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(episode.airDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
