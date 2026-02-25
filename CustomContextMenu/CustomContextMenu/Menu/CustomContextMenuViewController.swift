//
//  CustomContextMenuViewController.swift
//  CustomContextMenu
//
//  Created by Vladyslav Semenchenko on 18/02/2026.
//

import UIKit

/// Full-screen modal overlay that displays a custom context menu.
///
/// Presented with `.overFullScreen` so the previous screen remains visible behind a
/// semi-transparent dimming view. A tap outside the menu container dismisses it.
///
/// The menu container is manually positioned relative to the source view using coordinate
/// conversions through the window (see ``positionMenu()``).
///
final class CustomContextMenuViewController: UIViewController {

    // MARK: - Properties

    private let configuration: ContextMenuConfiguration
    private let containerView = UIView()
    private let stackView = UIStackView()
    private var backgroundTapGesture: UITapGestureRecognizer!

    // MARK: - Init

    init(configuration: ContextMenuConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupMenuItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Positioning is deferred to the next run-loop tick so that Auto Layout has
        // resolved the container's intrinsic size before we read it in `positionMenu()`.
        DispatchQueue.main.async {
            self.positionMenu()
            UIAccessibility.post(notification: .screenChanged, argument: self.containerView)
        }

        UIView.animate(withDuration: 0.15) {
            self.containerView.alpha = 1
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dismiss(animated: false)
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        containerView.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.00)
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.alpha = 0
        containerView.accessibilityViewIsModal = true

        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)
        view.addSubview(containerView)

        let trailingConstraint = stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        trailingConstraint.priority = UILayoutPriority(999)

        let bottomConstraint = stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            trailingConstraint,
            bottomConstraint
        ])

        backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        view.addGestureRecognizer(backgroundTapGesture)
    }

    private func setupMenuItems() {
        let detailFont = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        let maxDetailWidth = configuration.items.compactMap(\.detail).map {
            ceil(($0 as NSString).size(withAttributes: [.font: detailFont]).width)
        }.max() ?? 0

        for (index, item) in configuration.items.enumerated() {
            let itemView = createMenuItemView(for: item, maxDetailWidth: maxDetailWidth)
            stackView.addArrangedSubview(itemView)

            if index < configuration.items.count - 1 {
                let separator = createSeparator()
                stackView.addArrangedSubview(separator)
            }
        }
    }

    private func createMenuItemView(for item: ContextMenuItem, maxDetailWidth: CGFloat) -> UIView {
        let itemView = UIView()
        itemView.translatesAutoresizingMaskIntoConstraints = false

        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(handleItemTap(_:))
        )
        itemView.addGestureRecognizer(tapGesture)
        itemView.tag = configuration.items.firstIndex(where: { $0.id == item.id }) ?? 0

        itemView.isAccessibilityElement = true
        itemView.accessibilityTraits = .button
        itemView.accessibilityLabel = [item.title, item.statusText, item.detail]
            .compactMap { $0 }
            .joined(separator: ", ")

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false

        if let badge = item.badge {
            let badgeContainer = UIView()
            badgeContainer.backgroundColor = badge.color
            badgeContainer.layer.cornerRadius = 6
            badgeContainer.clipsToBounds = true
            badgeContainer.translatesAutoresizingMaskIntoConstraints = false

            let xmarkConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            let xmarkImageView = UIImageView(image: UIImage(systemName: "xmark", withConfiguration: xmarkConfig))
            xmarkImageView.tintColor = .white
            xmarkImageView.contentMode = .scaleAspectFit
            xmarkImageView.translatesAutoresizingMaskIntoConstraints = false

            badgeContainer.addSubview(xmarkImageView)
            NSLayoutConstraint.activate([
                badgeContainer.widthAnchor.constraint(equalToConstant: 24),
                badgeContainer.heightAnchor.constraint(equalToConstant: 24),
                xmarkImageView.centerXAnchor.constraint(equalTo: badgeContainer.centerXAnchor),
                xmarkImageView.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor)
            ])
            hStack.addArrangedSubview(badgeContainer)
        }

        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.spacing = 4
        contentStack.alignment = .center

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentStack.addArrangedSubview(titleLabel)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentStack.addArrangedSubview(spacer)

        if let statusText = item.statusText, let statusColor = item.statusColor {
            let statusLabel = UILabel()
            statusLabel.text = statusText
            statusLabel.textColor = statusColor
            statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
            statusLabel.setContentHuggingPriority(.required, for: .horizontal)
            contentStack.addArrangedSubview(statusLabel)
        }

        if let detail = item.detail {
            let detailLabel = UILabel()
            detailLabel.text = detail
            detailLabel.textColor = item.detailColor
            detailLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
            detailLabel.textAlignment = .right
            detailLabel.setContentHuggingPriority(.required, for: .horizontal)
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            detailLabel.widthAnchor.constraint(equalToConstant: maxDetailWidth).isActive = true
            contentStack.addArrangedSubview(detailLabel)
        }

        hStack.addArrangedSubview(contentStack)
        itemView.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: itemView.topAnchor, constant: 12),
            hStack.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -12),
            itemView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        return itemView
    }

    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.43, green: 0.43, blue: 0.44, alpha: 1.00)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 0.3).isActive = true
        return separator
    }

    // MARK: - Positioning

    /// Calculates and applies the menu container's frame relative to the source rect.
    ///
    /// **Coordinate conversion** (two-step, because the modal is a separate view hierarchy):
    /// 1. `sourceView.convert(sourceRect, to: window)` — source-local → window coordinates.
    /// 2. `view.convert(rectInWindow, from: window)`   — window → this modal's view coordinates.
    private func positionMenu() {
        view.layoutIfNeeded()

        guard let window = view.window ?? configuration.sourceView.window else { return }

        // Step 1: source view → window coordinates
        let rectInWindow = configuration.sourceView.convert(
            configuration.sourceRect, to: window
        )
        // Step 2: window → modal view coordinates
        let sourceRect = view.convert(rectInWindow, from: window)

        let menuWidth: CGFloat
        switch configuration.widthMode {
        case .auto:
            menuWidth = calculateAutoWidth()
        case .fixed(let width):
            menuWidth = width
        }

        let menuHeight = containerView.systemLayoutSizeFitting(
            CGSize(width: menuWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        var x = sourceRect.midX - menuWidth / 2
        var y = sourceRect.maxY + 8

        let padding: CGFloat = 16
        x = max(padding, min(x, view.bounds.width - menuWidth - padding))

        if y + menuHeight + padding > view.bounds.height {
            y = sourceRect.minY - menuHeight - 8
        }

        containerView.frame = CGRect(x: x, y: y, width: menuWidth, height: menuHeight)
    }

    /// Measures every item's text to determine the narrowest width that fits all content.
    ///
    /// Uses `NSString.size(withAttributes:)` with **hard-coded fonts** that must stay in
    /// sync with the fonts used in ``createMenuItemView(for:)``. If fonts change in one
    /// place but not the other, the auto-width will be wrong (items will clip or have
    /// excess padding).
    ///
    /// Result is clamped to **200–350 pt**.
    private func calculateAutoWidth() -> CGFloat {
        guard case .auto(let minWidth) = configuration.widthMode else { return 0 }

        var maxWidth: CGFloat = 0

        for item in configuration.items {
            var itemWidth: CGFloat = 24 // hStack leading(12) + trailing(12)

            if item.badge != nil {
                itemWidth += 24 + 12 // badge width + hStack.spacing
            }

            let titleSize = (item.title as NSString).size(withAttributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ])
            itemWidth += ceil(titleSize.width)

            // contentStack gaps: always title -> spacer, plus one per optional element
            var contentStackGaps = 1

            if let statusText = item.statusText {
                let statusSize = (statusText as NSString).size(withAttributes: [
                    .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
                ])
                itemWidth += ceil(statusSize.width)
                contentStackGaps += 1
            }

            if let detailText = item.detail {
                let detailSize = (detailText as NSString).size(withAttributes: [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
                ])
                itemWidth += ceil(detailSize.width)
                contentStackGaps += 1
            }

            itemWidth += CGFloat(contentStackGaps) * 4 // contentStack.spacing = 4

            maxWidth = max(maxWidth, itemWidth)
        }

        return max(minWidth, min(ceil(maxWidth), 350))
    }

    // MARK: - Actions

    @objc private func handleItemTap(_ gesture: UITapGestureRecognizer) {
        guard let itemView = gesture.view else { return }
        let index = itemView.tag
        let item = configuration.items[index]

        dismiss(animated: true) {
            item.action()
        }
    }

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            dismiss(animated: true)
        }
    }
}
