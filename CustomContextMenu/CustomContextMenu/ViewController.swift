//
//  ViewController.swift
//  CustomContextMenu
//
//  Created by Vladyslav Semenchenko on 18/02/2026.
//

// Demo view controller showcasing two `CustomContextMenu` usage patterns:
//
// 1. **Table view (per-cell menus)** — a single `CustomContextMenu` is attached to the
//    entire `UITableView`; the menu-builder closure resolves the tapped row from the
//    long-press location and returns row-specific items anchored to the cell rect.
//
// 2. **Plain UIView (single menu)** — a second `CustomContextMenu` is attached to a
//    standalone container view; it is hardcoded to `files.first` and anchors the menu
//    to the exact tap point using a zero-size source rect.

import UIKit

class ViewController: UIViewController {

    // MARK: - Properties

    private var contextMenu: CustomContextMenu?
    private var regularViewMenu: CustomContextMenu?
    private let tableView = UITableView()
    private let regularContainerView = UIView()
    private let regularMenuLabel = UILabel()

    private var files: [FileItem] = FileItem.mockFiles

    private let cellIdentifier = "FileCell"

    // MARK: - Lifecycle

    deinit {
        contextMenu?.detach()
        regularViewMenu?.detach()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        setupRegularView()
        setupContextMenu()
        setupRegularViewMenu()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupRegularView() {
        regularContainerView.translatesAutoresizingMaskIntoConstraints = false
        regularContainerView.backgroundColor = .secondarySystemBackground
        regularContainerView.layer.cornerRadius = 12

        regularMenuLabel.translatesAutoresizingMaskIntoConstraints = false
        regularMenuLabel.text = "Hold for menu"
        regularMenuLabel.textColor = .label
        regularMenuLabel.font = .systemFont(ofSize: 15, weight: .medium)

        regularContainerView.addSubview(regularMenuLabel)
        view.addSubview(regularContainerView)

        NSLayoutConstraint.activate([
            regularContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            regularContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            regularContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            regularContainerView.heightAnchor.constraint(equalToConstant: 48),

            regularMenuLabel.centerXAnchor.constraint(equalTo: regularContainerView.centerXAnchor),
            regularMenuLabel.centerYAnchor.constraint(equalTo: regularContainerView.centerYAnchor)
        ])

        // 76pt = 48pt (container height) + 12pt (top padding) + 16pt (gap below container)
        tableView.contentInset = UIEdgeInsets(top: 76, left: 0, bottom: 0, right: 0)
    }

    private func setupContextMenu() {
        contextMenu = CustomContextMenu()
        contextMenu?.attach(to: tableView) { [weak self] location in
            guard let self,
                  let indexPath = self.tableView.indexPathForRow(at: location)
            else { return nil }

            let file = self.files[indexPath.row]

            var items: [ContextMenuItem] = []

            items.append(ContextMenuItem(
                badge: file.isReady ? .ready : .pending,
                title: "Download",
                statusText: file.isReady ? "Ready" : "Pending",
                statusColor: file.isReady ? ContextMenuBadge.ready.color : ContextMenuBadge.pending.color,
                detail: file.formattedSize,
                detailColor: .systemGray,
                action: { [weak self] in
                    self?.downloadFile(file)
                }
            ))

            items.append(ContextMenuItem(
                title: "Share",
                statusText: file.isShared ? "Public" : nil,
                statusColor: .systemBlue,
                action: { [weak self] in
                    self?.shareFile(file)
                }
            ))

            items.append(ContextMenuItem(
                title: "Delete",
                statusText: "Permanent",
                statusColor: .systemRed,
                action: { [weak self] in
                    self?.confirmDelete(file)
                }
            ))

            let cellRect = self.tableView.rectForRow(at: indexPath)
            return ContextMenuConfiguration(
                items: items,
                sourceRect: cellRect,
                sourceView: self.tableView,
                widthMode: .auto
            )
        }
    }

    private func setupRegularViewMenu() {
        regularViewMenu = CustomContextMenu()
        regularViewMenu?.attach(to: regularContainerView) { [weak self] location in
            guard let self else { return nil }

            var items: [ContextMenuItem] = FileItem.mockVideos.map { video in
                ContextMenuItem(
                    badge: video.isReady ? .ready : .pending,
                    title: video.name,
                    statusText: video.isReady ? "Ready" : "Pending",
                    statusColor: video.isReady ? ContextMenuBadge.ready.color : ContextMenuBadge.pending.color,
                    detail: video.formattedSize,
                    detailColor: .systemGray,
                    action: { [weak self] in
                        self?.downloadFile(video)
                    }
                )
            }

            items.append(ContextMenuItem(
                title: "Share",
                action: { print("Share tapped") }
            ))

            return ContextMenuConfiguration(
                items: items,
                sourceRect: CGRect(origin: location, size: .zero),
                sourceView: self.regularContainerView,
                widthMode: .auto
            )
        }
    }

    // MARK: - Actions

    private func downloadFile(_ file: FileItem) {
        print("Downloading \(file.name)...")
    }

    private func shareFile(_ file: FileItem) {
        print("Sharing \(file.name)...")
    }

    private func confirmDelete(_ file: FileItem) {
        print("Show delete confirmation...")
    }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        files.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let file = files[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = file.name
        content.secondaryText = file.formattedSize
        content.image = UIImage(systemName: file.isReady ? "checkmark.circle.fill" : "clock")
        content.imageProperties.tintColor = file.isReady ? .systemGreen : .systemRed
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("Selected file: \(files[indexPath.row].name)")
    }
}
