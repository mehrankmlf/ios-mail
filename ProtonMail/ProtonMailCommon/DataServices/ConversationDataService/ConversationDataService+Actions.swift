//
//  ConversationDataService+Actions.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
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

import Foundation

extension ConversationDataService {
    func deleteConversations(with conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationDeleteRequest(conversationIDs: conversationIDs.map(\.rawValue), labelID: labelID.rawValue)
        self.apiService.exec(route: request, responseObject: ConversationDeleteResponse()) { (task, response) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }

            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(()))
        }
    }

    func markAsRead(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationReadRequest(conversationIDs: conversationIDs.map(\.rawValue))
        self.apiService.exec(route: request, responseObject: ConversationReadResponse()) { (task, response) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }
            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(()))
        }
    }

    func markAsUnread(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationUnreadRequest(conversationIDs: conversationIDs.map(\.rawValue), labelID: labelID.rawValue)
        self.apiService.exec(route: request, responseObject: ConversationUnreadResponse()) { (task, response) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }

            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            completion?(.success(()))
        }
    }

    func label(conversationIDs: [ConversationID],
               as labelID: LabelID,
               isSwipeAction: Bool,
               completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationLabelRequest(conversationIDs: conversationIDs.map(\.rawValue), labelID: labelID.rawValue)
        self.apiService.exec(route: request, responseObject: ConversationLabelResponse()) { [weak self] (task, response) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }

            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            if let undoTokenData = response.undoTokenData {
                let type = self?.undoActionManager.calculateUndoActionBy(labelID: labelID.rawValue)
                self?.undoActionManager.addUndoToken(undoTokenData,
                                                     undoActionType: type)
            }
            completion?(.success(()))
        }
    }

    func unlabel(conversationIDs: [ConversationID],
                 as labelID: LabelID,
                 isSwipeAction: Bool,
                 completion: ((Result<Void, Error>) -> Void)?) {
        let request = ConversationUnlabelRequest(conversationIDs: conversationIDs.map(\.rawValue), labelID: labelID.rawValue)
        self.apiService.exec(route: request, responseObject: ConversationUnlabelResponse()) { [weak self] (task, response) in
            if let err = response.error {
                completion?(.failure(err))
                return
            }

            guard response.results != nil else {
                let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                completion?(.failure(err))
                return
            }
            if let undoTokenData = response.undoTokenData {
                let type = self?.undoActionManager.calculateUndoActionBy(labelID: labelID.rawValue)
                self?.undoActionManager.addUndoToken(undoTokenData,
                                                     undoActionType: type)
            }
            completion?(.success(()))
        }
    }

    func move(conversationIDs: [ConversationID],
              from previousFolderLabel: LabelID,
              to nextFolderLabel: LabelID,
              isSwipeAction: Bool,
              completion: ((Result<Void, Error>) -> Void)?) {
        let conversations = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs), in: contextProvider.rootSavingContext)
        let labelAction = { [weak self] in
            guard !nextFolderLabel.rawValue.isEmpty else {
                completion?(.failure(ConversationError.emptyLabel))
                return
            }
            let idsToLabel = conversations.map{ ConversationID($0.conversationID) }
            self?.label(conversationIDs: idsToLabel, as: nextFolderLabel, isSwipeAction: isSwipeAction, completion: completion)
        }
        guard !previousFolderLabel.rawValue.isEmpty else {
            labelAction()
            return
        }
        let idsToUnlabel = conversations.map{ ConversationID($0.conversationID) }
        unlabel(conversationIDs: idsToUnlabel, as: previousFolderLabel, isSwipeAction: isSwipeAction) { result in
            switch result {
            case .success:
                labelAction()
            case .failure:
                break
            }
        }
    }
}
