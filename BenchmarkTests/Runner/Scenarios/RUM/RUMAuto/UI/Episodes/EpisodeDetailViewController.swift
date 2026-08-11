/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI
import UIKit

@MainActor
class EpisodeDetailViewController: UIViewController {
    var episode: Episode?
    private var characters: [Character] = []

    @IBOutlet private var episodeCodeLabel: UILabel!
    @IBOutlet private var episodeCodeValueLabel: UILabel!
    @IBOutlet private var airDateLabel: UILabel!
    @IBOutlet private var airDateValueLabel: UILabel!
    @IBOutlet private var createdLabel: UILabel!
    @IBOutlet private var createdValueLabel: UILabel!
    @IBOutlet private var charactersCountLabel: UILabel!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        fetchCharacters()
    }

    private func setupUI() {
        guard let episode else {
            return
        }

        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never

        titleLabel.text = episode.name
        episodeCodeValueLabel.text = episode.episode
        airDateValueLabel.text = episode.airDate
        createdValueLabel.text = formatDate(episode.created)
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    private func fetchCharacters() {
        guard let episode else {
            return
        }

        Task {
            do {
                let characterIds = episode.characters.compactMap { url -> Int? in
                    guard let id = url.split(separator: "/").last else {
                        return nil
                    }
                    return Int(id)
                }

                characters = try await RickMortyService.shared.fetchCharactersByIds(characterIds)
                charactersCountLabel.text = "Characters: \(characters.count)"
                collectionView.reloadData()
            } catch {
                print("Error loading characters: \(error)")
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension EpisodeDetailViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CharacterCell", for: indexPath) as! CharacterCollectionViewCell
        let character = characters[indexPath.item]
        cell.configure(with: character)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension EpisodeDetailViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let character = characters[indexPath.item]
        let characterDetailView = CharacterDetailView(character: character)
        let hostingController = UIHostingController(rootView: characterDetailView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
}
