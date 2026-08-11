/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import Foundation
import ArgumentParser
import CodeGeneration

private struct RootCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generates RUM models from given schema file and prints it to the standard output.",
        subcommands: [
            GenerateSwift.self,
            GenerateObjc.self
        ]
    )

    /// Convention of decorating generated code.
    /// It impacts naming, visibility and structure of generated code.
    enum Convention: String, ExpressibleByArgument {
        /// Decorate generated code using RUM conventions.
        case rum = "rum"
        /// Decorate generated code using Session Replay conventions.
        case sessionReplay = "sr"
    }

    struct GenerateSwift: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "generate-swift",
            abstract: "Generates models for Atatus Swift."
        )

        @Option(help: "The path to the JSON schema.")
        var path: String

        @Option(help: "Convention of decorating generated code: 'rum' (default) or 'sr'.")
        var convention: Convention = .rum

        func run() throws {
            let schemaURL = URL(fileURLWithPath: path)
            switch convention {
            case .rum:
                print(try generateRUMSwiftModels(from: schemaURL))
            case .sessionReplay:
                print(try generateSRSwiftModels(from: schemaURL))
            }
        }
    }

    struct GenerateObjc: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "generate-objc",
            abstract: "Generates models for Atatus Objc."
        )

        @Option(help: "The path to the JSON schema.")
        var path: String

        @Option(help: "Convention of decorating generated code: 'rum' (default) or 'sr'.")
        var convention: Convention = .rum

        @Option(help: "List of type names to skip from code generation.")
        var skip: [String] = []

        func run() throws {
            let schemaURL = URL(fileURLWithPath: path)
            switch convention {
            case .rum:
                print(try generateRUMObjcInteropModels(from: schemaURL, skip: .init(skip)))
            case .sessionReplay:
                print(try generateSRObjcInteropModels(from: schemaURL, skip: .init(skip)))
            }
        }
    }
}

RootCommand.main()
