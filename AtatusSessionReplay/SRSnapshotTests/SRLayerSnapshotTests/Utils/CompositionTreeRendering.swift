/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

import UIKit
@_spi(Internal)
@testable import AtatusSessionReplay

@available(iOS 13.0, *)
internal struct CompositionTreeRenderingDebugInfo {
    fileprivate let compositionTree: SRCompositionTree
    fileprivate let wireframes: [SRWireframe]

    func dumpCompositionTreeAsJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try? encoder.encode(compositionTree)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "(JSON encoding failed)"
    }

    func dumpWireframesAsJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try? encoder.encode(wireframes)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "(JSON encoding failed)"
    }
}

@available(iOS 13.0, *)
@MainActor
internal func renderImage(
    for compositionTree: SRCompositionTree,
    wireframes: [SRWireframe],
    resources: [Resource]
) -> (image: UIImage, debugInfo: CompositionTreeRenderingDebugInfo) {
    let identifiedLayers = Dictionary(
        uniqueKeysWithValues: (compositionTree.layers ?? []).map { ($0.id, $0) }
    )
    let identifiedWireframes = Dictionary(uniqueKeysWithValues: wireframes.map { ($0.id, $0) })
    let identifiedResources = Dictionary(
        resources.map { ($0.calculateIdentifier(), $0) },
        uniquingKeysWith: { resource, _ in resource }
    )

    let root = compositionTree.root
    let view = CompositionLayerView(
        root,
        identifiedLayers: identifiedLayers,
        identifiedWireframes: identifiedWireframes,
        identifiedResources: identifiedResources,
        parentFrame: root.absoluteFrame
    )
    view.layoutIfNeeded()

    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: root.size, format: format)
    return (
        renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        },
        CompositionTreeRenderingDebugInfo(compositionTree: compositionTree, wireframes: wireframes)
    )
}
