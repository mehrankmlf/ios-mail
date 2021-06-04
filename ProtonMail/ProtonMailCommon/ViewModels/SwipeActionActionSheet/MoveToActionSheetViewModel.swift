//
//  MoveToActionSheetViewModel.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

protocol MoveToActionSheetViewModel {
    var menuLabels: [MenuLabel] { get }
    var isEnableColor: Bool { get }
    var isInherit: Bool { get }
    var initialLabelSelectionStatus: [MenuLabel: PMActionSheetPlainItem.MarkType] { get }
    func getColor(of label: MenuLabel) -> UIColor
}

extension MoveToActionSheetViewModel {
    func getColor(of label: MenuLabel) -> UIColor {
        guard label.location.icon == nil else {
            return UIColorManager.IconNorm
        }

        guard isEnableColor else { return UIColorManager.IconNorm }
        if isInherit {
            guard let parent = menuLabels.getRootItem(of: label) else {
                return UIColor(hexColorCode: "#FFFFFF")
            }
            return UIColor(hexColorCode: parent.iconColor)
        } else {
            return UIColor(hexColorCode: label.iconColor)
        }
    }
}

struct MoveToActionSheetViewModelMessages: MoveToActionSheetViewModel {
    let menuLabels: [MenuLabel]
    let isEnableColor: Bool
    let isInherit: Bool
    let labelId: String
    private var initialLabelSelectionCount: [MenuLabel: Int] = [:]
    private(set) var initialLabelSelectionStatus: [MenuLabel: PMActionSheetPlainItem.MarkType] = [:]

    init(menuLabels: [MenuLabel],
         messages: [Message],
         isEnableColor: Bool,
         isInherit: Bool,
         labelId: String) {
        self.isInherit = isInherit
        self.isEnableColor = isEnableColor
        self.labelId = labelId
        self.menuLabels = menuLabels

        let labelCount = menuLabels.getNumberOfRows()
        for i in 0..<labelCount {
            let indexPath = IndexPath(row: i, section: 0)
            if let label = menuLabels.getFolderItem(by: indexPath) {
                initialLabelSelectionCount[label] = 0
            }
        }

        initialLabelSelectionCount.forEach { (label, _) in
            for msg in messages where msg.contains(label: label.location.labelID) {
                if let labelCount = initialLabelSelectionCount[label] {
                    initialLabelSelectionCount[label] = labelCount + 1
                } else {
                    initialLabelSelectionCount[label] = 1
                }
            }
        }

        initialLabelSelectionCount.forEach { (key, value) in
            if value == messages.count {
                initialLabelSelectionStatus[key] = .checkMark
            } else if value < messages.count && value > 0 {
                initialLabelSelectionStatus[key] = .dash
            } else {
                initialLabelSelectionStatus[key] = PMActionSheetPlainItem.MarkType.none
            }
        }
    }
}

struct MoveToActionSheetViewModelConversations: MoveToActionSheetViewModel {
    let menuLabels: [MenuLabel]
    let isEnableColor: Bool
    let isInherit: Bool
    let labelId: String
    private var initialLabelSelectionCount: [MenuLabel: Int] = [:]
    private(set) var initialLabelSelectionStatus: [MenuLabel: PMActionSheetPlainItem.MarkType] = [:]

    init(menuLabels: [MenuLabel],
         conversations: [Conversation],
         isEnableColor: Bool,
         isInherit: Bool,
         labelId: String) {
        self.isInherit = isInherit
        self.isEnableColor = isEnableColor
        self.labelId = labelId
        self.menuLabels = menuLabels

        let labelCount = menuLabels.getNumberOfRows()
        for i in 0..<labelCount {
            let indexPath = IndexPath(row: i, section: 0)
            if let label = menuLabels.getFolderItem(by: indexPath) {
                initialLabelSelectionCount[label] = 0
            }
        }

        initialLabelSelectionCount.forEach { (label, _) in
            for conversation in conversations where conversation.getLabels().contains(label.location.labelID) {
                if let labelCount = initialLabelSelectionCount[label] {
                    initialLabelSelectionCount[label] = labelCount + 1
                } else {
                    initialLabelSelectionCount[label] = 1
                }
            }
        }

        initialLabelSelectionCount.forEach { (key, value) in
            if value == conversations.count {
                initialLabelSelectionStatus[key] = .checkMark
            } else if value < conversations.count && value > 0 {
                initialLabelSelectionStatus[key] = .dash
            } else {
                initialLabelSelectionStatus[key] = PMActionSheetPlainItem.MarkType.none
            }
        }
    }
}
