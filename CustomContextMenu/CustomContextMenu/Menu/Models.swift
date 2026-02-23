//
//  Models.swift
//  CustomContextMenu
//
//  Created by Vladyslav Semenchenko on 18/02/2026.
//

import UIKit

// MARK: - Width Mode

enum ContextMenuWidthMode {
    case auto
    case fixed(CGFloat)

    var defaultWidth: CGFloat {
        switch self {
        case .auto: return 0
        case .fixed(let width): return width
        }
    }
}

// MARK: - Badge

enum ContextMenuBadge {
    case ready
    case pending

    var color: UIColor {
        switch self {
        case .ready:   return UIColor(red: 0.17, green: 0.47, blue: 0.28, alpha: 1.0)
        case .pending: return UIColor(red: 0.55, green: 0.14, blue: 0.14, alpha: 1.0)
        }
    }
}

// MARK: - Menu Item

/// A single row in the custom context menu.
///
/// **Layout** (left to right):
/// ```
/// [ badge | title | spacer | statusText | detail ]
/// ```
struct ContextMenuItem {
    let id = UUID()
    let badge: ContextMenuBadge?
    let title: String
    let statusText: String?
    let statusColor: UIColor?
    let detail: String?
    let detailColor: UIColor
    let action: () -> Void

    init(
        badge: ContextMenuBadge? = nil,
        title: String,
        statusText: String? = nil,
        statusColor: UIColor? = nil,
        detail: String? = nil,
        detailColor: UIColor = .secondaryLabel,
        action: @escaping () -> Void
    ) {
        self.badge = badge
        self.title = title
        self.statusText = statusText
        self.statusColor = statusColor
        self.detail = detail
        self.detailColor = detailColor
        self.action = action
    }
}

// MARK: - Configuration

/// All the information needed to present a custom context menu.
struct ContextMenuConfiguration {
    let items: [ContextMenuItem]
    let sourceRect: CGRect
    let sourceView: UIView
    let widthMode: ContextMenuWidthMode

    init(
        items: [ContextMenuItem],
        sourceRect: CGRect,
        sourceView: UIView,
        widthMode: ContextMenuWidthMode = .fixed(250)
    ) {
        self.items = items
        self.sourceRect = sourceRect
        self.sourceView = sourceView
        self.widthMode = widthMode
    }
}
