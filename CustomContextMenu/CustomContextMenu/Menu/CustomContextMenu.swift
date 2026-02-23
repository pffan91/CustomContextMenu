//
//  CustomContextMenu.swift
//  CustomContextMenu
//
//  Created by Vladyslav Semenchenko on 18/02/2026.
//

import UIKit

/// Bridges UIKit's long-press context-menu gesture to a fully custom menu presentation.
final class CustomContextMenu: NSObject, UIContextMenuInteractionDelegate {

    // MARK: - Properties

    private weak var targetView: UIView?
    private var configurationProvider: ((CGPoint) -> ContextMenuConfiguration?)?
    private var interaction: UIContextMenuInteraction?

    deinit {
        detach()
    }

    // MARK: - Public API

    /// Installs a `UIContextMenuInteraction` on `view` and stores the configuration closure.
    func attach(
        to view: UIView,
        configurationProvider: @escaping (CGPoint) -> ContextMenuConfiguration?
    ) {
        self.targetView = view
        self.configurationProvider = configurationProvider

        let interaction = UIContextMenuInteraction(delegate: self)
        view.addInteraction(interaction)
        self.interaction = interaction
    }

    /// Uninstalls the interaction and clears references to avoid retain cycles.
    func detach() {
        if let interaction, let view = targetView {
            view.removeInteraction(interaction)
        }
        interaction = nil
        targetView = nil
        configurationProvider = nil
    }

    // MARK: - Presentation

    /// Presents the custom menu modally from the root view controller.
    ///
    /// Must be called on the **main thread** (it triggers UIKit presentation).
    func presentMenu(at location: CGPoint) {
        // NOTE: Haptic fires *before* the guard — the user feels a tap even when the
        // menu won't appear (e.g., configurationProvider returns nil).
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        guard let targetView,
              let viewController = targetView.window?.rootViewController,
              let config = configurationProvider?(location) else { return }

        let menuVC = CustomContextMenuViewController(configuration: config)
        viewController.present(menuVC, animated: true)
    }

    // MARK: - UIContextMenuInteractionDelegate

    /// Intercepts UIKit's native context-menu flow and replaces it with the custom menu.
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        DispatchQueue.main.async { [weak self] in
            self?.presentMenu(at: location)
        }
        return nil
    }
}
