//
//  FileItemModel.swift
//  CustomContextMenu
//
//  Created by Vladyslav Semenchenko on 18/02/2026.
//

import Foundation

struct FileItem: Identifiable {
    let id: UUID
    let name: String
    let sizeInBytes: Int
    let isReady: Bool
    let isShared: Bool

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(sizeInBytes), countStyle: .file)
    }

    init(
        id: UUID = .init(),
        name: String,
        sizeInBytes: Int,
        isReady: Bool = false,
        isShared: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sizeInBytes = sizeInBytes
        self.isReady = isReady
        self.isShared = isShared
    }
}

extension FileItem {
    static let mockFiles: [FileItem] = [
        .init(name: "Report.pdf", sizeInBytes: 1_234_567, isReady: true,  isShared: true),
        .init(name: "Presentation.pptx", sizeInBytes: 8_192_000, isReady: true,  isShared: false),
        .init(name: "Photo.jpg", sizeInBytes: 345_678, isReady: false, isShared: false),
        .init(name: "Archive.zip", sizeInBytes: 25_000_000, isReady: true, isShared: true),
        .init(name: "Video.mp4", sizeInBytes: 120_000_000, isReady: false, isShared: false)
    ]

    static let mockVideos: [FileItem] = [
        .init(name: "Video 1", sizeInBytes: 2_500_000, isReady: true),
        .init(name: "Video 2", sizeInBytes: 15_700_000, isReady: false)
    ]
}
