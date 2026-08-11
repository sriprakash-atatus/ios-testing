/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import UIKit

internal class RUMTASTableViewCustomCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
}

internal class RUMTASTableViewController: UITableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        if indexPath.item % 2 == 0 {
            let systemBasicCell = tableView.dequeueReusableCell(withIdentifier: "SystemBasicCell")!
            systemBasicCell.textLabel?.text = "Item \(indexPath.item)"
            cell = systemBasicCell
        } else {
            let customCell = tableView.dequeueReusableCell(withIdentifier: "CustomCell") as! RUMTASTableViewCustomCell
            customCell.label.text = "Item \(indexPath.item)"
            cell = customCell
        }

        cell.accessibilityIdentifier = "Item \(indexPath.item)"

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.popViewController(animated: true)
    }
}
