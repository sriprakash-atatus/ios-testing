/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI
import UIKit

/// Decoded images kept in memory, so a product scrolled back into view shows instantly instead of flickering.
final class ImageMemoryCache: @unchecked Sendable {
    static let shared = ImageMemoryCache()

    private let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 400
        cache.totalCostLimit = 120 * 1024 * 1024
        return cache
    }()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

/// Downloads images once per URL — concurrent requests for the same image share one download — and
/// backs them with a disk cache.
actor ImagePipeline {
    static let shared = ImagePipeline()

    private let session: URLSession
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 16 * 1024 * 1024, diskCapacity: 256 * 1024 * 1024)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 20
        session = URLSession(configuration: configuration)
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = ImageMemoryCache.shared.image(for: url) {
            return cached
        }
        if let running = inFlight[url] {
            return try await running.value
        }

        let session = self.session
        let task = Task<UIImage, Error> {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            guard let image = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            // Decodes off the main thread, so the first frame that shows the image doesn't hitch.
            return await image.byPreparingForDisplay() ?? image
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        ImageMemoryCache.shared.insert(image, for: url)
        return image
    }
}

/// An image from the network: a shimmer while it loads, a symbol if it can't.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fit
    var fallbackSymbol: String = "photo"

    @State private var loaded: LoadedImage?
    @State private var failedURL: URL?

    init(url: URL?, contentMode: ContentMode = .fit, fallbackSymbol: String = "photo") {
        self.url = url
        self.contentMode = contentMode
        self.fallbackSymbol = fallbackSymbol
        if let url = url, let cached = ImageMemoryCache.shared.image(for: url) {
            _loaded = State(initialValue: LoadedImage(url: url, image: cached))
        }
    }

    var body: some View {
        ZStack {
            if let loaded = loaded, loaded.url == url {
                Image(uiImage: loaded.image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else if url == nil || (failedURL != nil && failedURL == url) {
                Image(systemName: fallbackSymbol)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.surfaceMuted
                    .shimmer()
            }
        }
        .task(id: url) {
            await load()
        }
        .accessibilityHidden(true)
    }

    private func load() async {
        guard let url = url, loaded?.url != url else {
            return
        }
        do {
            let image = try await ImagePipeline.shared.image(for: url)
            withAnimation(.easeOut(duration: 0.2)) {
                loaded = LoadedImage(url: url, image: image)
            }
        } catch {
            if !Task.isCancelled {
                failedURL = url
            }
        }
    }
}

private struct LoadedImage {
    let url: URL
    let image: UIImage
}

/// A product photo on the light well product images are shot for.
struct ProductImageView: View {
    let product: Product
    /// Defaults to the product's thumbnail.
    var url: URL?
    var contentMode: ContentMode = .fit
    var padding: CGFloat = Theme.Spacing.xs

    init(product: Product, url: URL? = nil, contentMode: ContentMode = .fit, padding: CGFloat = Theme.Spacing.xs) {
        self.product = product
        self.url = url
        self.contentMode = contentMode
        self.padding = padding
    }

    var body: some View {
        RemoteImage(url: url ?? product.thumbnailURL, contentMode: contentMode, fallbackSymbol: product.symbolName)
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.imageWell)
    }
}

extension Color {
    /// The light grey product photos sit on, in both appearances — the photos are shot on white.
    static let imageWell = Color(light: 0xF3F4F6, dark: 0xE9EAEE)
}
