//
//  CacheService.swift
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

import Foundation
import CoreData
import Groot
import ProtonCore_DataModel

class CacheService: Service {
    let userID: String
    let lastUpdatedStore: LastUpdatedStoreProtocol
    let coreDataService: CoreDataService
    private var context: NSManagedObjectContext {
        return self.coreDataService.rootSavingContext
    }

    init(userID: String, lastUpdatedStore: LastUpdatedStoreProtocol, coreDataService: CoreDataService) {
        self.userID = userID
        self.lastUpdatedStore = lastUpdatedStore
        self.coreDataService = coreDataService
    }

    // MARK: - Message related functions
    func move(message: Message, from fLabel: String, to tLabel: String) -> Bool {
        var hasError = false
        context.performAndWait {
            guard let msgToUpdate = try? context.existingObject(with: message.objectID) as? Message else {
                hasError = true
                return
            }

            if let lid = msgToUpdate.remove(labelID: fLabel), msgToUpdate.unRead {
                self.updateCounterSync(plus: false, with: lid, context: context)
                if let id = msgToUpdate.selfSent(labelID: lid) {
                    self.updateCounterSync(plus: false, with: id, context: context)
                }
            }
            if let lid = msgToUpdate.add(labelID: tLabel) {
                // if move to trash. clean lables.
                var labelsFound = msgToUpdate.getNormalLabelIDs()
                labelsFound.append(Message.Location.starred.rawValue)
                labelsFound.append(Message.Location.allmail.rawValue)
                if lid == Message.Location.trash.rawValue {
                    self.removeLabel(on: msgToUpdate, labels: labelsFound, cleanUnread: true)
                    msgToUpdate.unRead = false
                }
                if lid == Message.Location.spam.rawValue {
                    self.removeLabel(on: msgToUpdate, labels: labelsFound, cleanUnread: false)
                }

                if msgToUpdate.unRead {
                    self.updateCounterSync(plus: true, with: lid, context: context)
                    if let id = msgToUpdate.selfSent(labelID: lid) {
                        self.updateCounterSync(plus: true, with: id, context: context)
                    }
                }
            }

            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }
        return !hasError
    }

    func delete(message: Message, label: String) -> Bool {
        var contextToUse = self.context
        guard let msgContext = message.managedObjectContext else {
            return false
        }

        if msgContext.concurrencyType == .mainQueueConcurrencyType && msgContext != self.coreDataService.mainContext {
            contextToUse = msgContext
        }

        var hasError = false
        contextToUse.performAndWait {
            guard let msgToUpdate = try? contextToUse.existingObject(with: message.objectID) as? Message else {
                hasError = true
                return
            }

            if let lid = msgToUpdate.remove(labelID: label), msgToUpdate.unRead {
                self.updateCounterSync(plus: false, with: lid, context: context)
                if let id = msgToUpdate.selfSent(labelID: lid) {
                    self.updateCounterSync(plus: false, with: id, context: context)
                }
            }
            var labelsFound = msgToUpdate.getNormalLabelIDs()
            labelsFound.append(Message.Location.starred.rawValue)
            labelsFound.append(Message.Location.allmail.rawValue)
            self.removeLabel(on: msgToUpdate, labels: labelsFound, cleanUnread: true)
            let labelObjs = msgToUpdate.mutableSetValue(forKey: "labels")
            labelObjs.removeAllObjects()
            msgToUpdate.setValue(labelObjs, forKey: "labels")
            contextToUse.delete(msgToUpdate)

            let error = contextToUse.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }

        if hasError {
            return false
        }

        return true
    }

    func mark(message: Message, labelID: String, unRead: Bool) -> Bool {
        var hasError = false
        context.performAndWait {
            guard let msgToUpdate = try? context.existingObject(with: message.objectID) as? Message else {
                hasError = true
                return
            }

            msgToUpdate.unRead = unRead

            if let conversation = Conversation.conversationForConversationID(msgToUpdate.conversationID, inManagedObjectContext: context) {
                conversation.applySingleMarkAsChanges(unRead: unRead, labelID: labelID)
            }

            self.updateCounterSync(markUnRead: unRead, on: msgToUpdate, context: context)

            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }

        if hasError {
            return false
        }
        return true
    }

    func label(messages: [Message], label: String, apply: Bool) -> Bool {
        var result = false
        var hasError = false
        context.performAndWait {
            for message in messages {
                guard let msgToUpdate = try? context.existingObject(with: message.objectID) as? Message else {
                    hasError = true
                    continue
                }

                if apply {
                    if msgToUpdate.add(labelID: label) != nil && msgToUpdate.unRead {
                        self.updateCounterSync(plus: true, with: label, context: context)
                    }
                } else {
                    if msgToUpdate.remove(labelID: label) != nil && msgToUpdate.unRead {
                        self.updateCounterSync(plus: false, with: label, context: context)
                    }
                }

                if let conversation = Conversation.conversationForConversationID(msgToUpdate.conversationID, inManagedObjectContext: context) {
                    conversation.applyLabelChangesOnOneMessage(labelID: label, apply: apply)
                }
            }

            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }

        if hasError {
            result = false
        }
        result = true
        return result
    }

    func removeLabel(on message: Message, labels: [String], cleanUnread: Bool) {
        guard let context = message.managedObjectContext else {
            return
        }
        let unread = cleanUnread ? message.unRead : cleanUnread
        for label in labels {
            if let labelId = message.remove(labelID: label), unread {
                self.updateCounterSync(plus: false, with: labelId, context: context)
                if let id = message.selfSent(labelID: labelId) {
                    self.updateCounterSync(plus: false, with: id, context: context)
                }
            }
        }
    }

    func deleteMessage(by labelID: String) -> Bool {
        var result = false
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)

        fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K == %@)", "\(labelID)", Message.Attributes.userID, self.userID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
        context.performAndWait {
            do {
                if let oldMessages = try context.fetch(fetchRequest) as? [Message] {
                    for message in oldMessages {
                        context.delete(message)
                    }
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(error)")
                    } else {
                        result = true
                    }
                }
            } catch {
                PMLog.D(" error: \(error)")
            }
        }
        return result
    }

    func deleteMessage(messageID: String, completion: (() -> Void)? = nil) {
        context.perform {
            if let msg = Message.messageForMessageID(messageID, inManagedObjectContext: self.context) {
                let labelObjs = msg.mutableSetValue(forKey: Message.Attributes.labels)
                labelObjs.removeAllObjects()
                self.context.delete(msg)
            }
            if let error = self.context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
            completion?()
        }
    }

    func cleanReviewItems(completion: (() -> Void)? = nil) {
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 1) AND (%K == %@)", Message.Attributes.messageType, Message.Attributes.userID, self.userID)
            do {
                if let messages = try self.context.fetch(fetchRequest) as? [Message] {
                    for msg in messages {
                        self.context.delete(msg)
                    }
                    if let error = self.context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    }
                }
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
            completion?()
        }
    }

    func updateExpirationOffset(of message: Message,
                                expirationTime: TimeInterval,
                                pwd: String,
                                pwdHint: String,
                                completion: (() -> Void)?) {
        let contextToUse = message.managedObjectContext ?? context
        contextToUse.perform {
            if let msg = try? self.context.existingObject(with: message.objectID) as? Message {
                msg.time = Date()
                msg.password = pwd
                msg.passwordHint = pwdHint
                msg.expirationOffset = Int32(expirationTime)
                if let error = contextToUse.saveUpstreamIfNeeded() {
                    PMLog.D(" error: \(error)")
                }
            }
            completion?()
        }
    }

    func deleteExpiredMessage(completion: (() -> Void)?) {
        context.perform {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetch.predicate = NSPredicate(format: "%K != NULL AND %K < %@",
                                          Message.Attributes.expirationTime,
                                          Message.Attributes.expirationTime,
                                          NSDate())

            if let messages = try? self.context.fetch(fetch) as? [Message] {
                messages.forEach { (msg) in
                    if msg.unRead {
                        let labels: [String] = msg.getLabelIDs()
                        labels.forEach { (label) in
                            self.updateCounterSync(plus: false, with: label, context: self.context)
                        }
                    }
                    self.context.delete(msg)
                }
                if let error = self.context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
}

// MARK: - Attachment related functions
extension CacheService {
    func delete(attachment: Attachment, completion: (() -> Void)?) {
        context.perform {
            if let att = try? self.context.existingObject(with: attachment.objectID) as? Attachment {
                att.isSoftDeleted = true
                _ = self.context.saveUpstreamIfNeeded()
            }
            completion?()
        }
    }

    func cleanOldAttachment() {
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Attachment.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 1) AND %K == NULL", Attachment.Attributes.isSoftDelete, Attachment.Attributes.message)
            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try self.context.execute(request)
            } catch let ex as NSError {
                Analytics.shared.error(message: .purgeOldMessages,
                                       error: ex,
                                       user: nil)
                PMLog.D("error : \(ex)")
            }
        }
    }
}

extension CacheService {
    func parseMessagesResponse(labelID: String, isUnread: Bool, response: [String: Any], completion: ((Error?) -> Void)?) {
        guard var messagesArray = response["Messages"] as? [[String: Any]] else {
            completion?(NSError.unableToParseResponse(response))
            return
        }

        for (index, _) in messagesArray.enumerated() {
            messagesArray[index]["UserID"] = self.userID
        }
        let messagesCount = response["Total"] as? Int ?? 0

        context.perform {
            //Prevent the draft is overriden while sending
            if labelID == Message.Location.draft.rawValue, let sendingMessageIDs = Message.getIDsofSendingMessage(managedObjectContext: self.context) {
                let idsSet = Set(sendingMessageIDs)
                var msgIDsOfMessageToRemove: [String] = []

                messagesArray.forEach { (messageDict) in
                    if let msgID = messageDict["ID"] as? String, idsSet.contains(msgID) {
                        msgIDsOfMessageToRemove.append(msgID)
                    }
                }

                msgIDsOfMessageToRemove.forEach { (msgID) in
                    messagesArray.removeAll { (msgDict) -> Bool in
                        if let id = msgDict["ID"] as? String {
                            return id == msgID
                        }
                        return false
                    }
                }
            }

            do {
                if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: self.context) as? [Message] {
                    for msg in messages {
                        // mark the status of metadata being set
                        msg.messageStatus = 1
                    }
                    if let err = self.context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(err)")
                    }

                    if let lastMsg = messages.last, let firstMsg = messages.first {
                        self.updateLastUpdatedTime(labelID: labelID, isUnread: isUnread, startTime: firstMsg.time ?? Date(), endTime: lastMsg.time ?? Date(), msgCount: messagesCount, msgType: .singleMessage)
                    }

                    completion?(nil)
                }
            } catch {
                PMLog.D("error: \(error)")
                completion?(error)
            }
        }
    }
}

// MARK: - Counter related functions
extension CacheService {
    func updateLastUpdatedTime(labelID: String, isUnread: Bool, startTime: Date, endTime: Date, msgCount: Int, msgType: ViewMode) {
        context.performAndWait {
            let updateTime = self.lastUpdatedStore.lastUpdateDefault(by: labelID, userID: self.userID, context: context, type: msgType)
            if isUnread {
                //Update unread date query time
                if updateTime.isUnreadNew {
                    updateTime.unreadStart = startTime
                }
                if updateTime.unreadEndTime.compare(endTime) == .orderedDescending || updateTime.unreadEndTime == .distantPast {
                    updateTime.unreadEnd = endTime
                }
                updateTime.unreadUpdate = Date()
            } else {
                if updateTime.isNew {
                    updateTime.start = startTime
                    updateTime.total = Int32(msgCount)
                }
                if updateTime.endTime.compare(endTime) == .orderedDescending || updateTime.endTime == .distantPast {
                    updateTime.end = endTime
                }
                updateTime.update = Date()
            }
            if let err = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(err)")
            }
        }
    }

    func updateCounterSync(markUnRead: Bool, on message: Message, context: NSManagedObjectContext) {
        let offset = markUnRead ? 1 : -1
        let labelIDs: [String] = message.getLabelIDs()
        for lID in labelIDs {
            let unreadCount: Int = lastUpdatedStore.unreadCount(by: lID, userID: self.userID, type: .singleMessage)
            var count = unreadCount + offset
            if count < 0 {
                count = 0
            }
            lastUpdatedStore.updateUnreadCount(by: lID, userID: self.userID, count: count, type: .singleMessage, shouldSave: false)

            // Conversation Count
            let conversationUnreadCount: Int = lastUpdatedStore.unreadCount(by: lID, userID: self.userID, type: .conversation)
            var conversationCount = conversationUnreadCount + offset
            if conversationCount < 0 {
                conversationCount = 0
            }
            lastUpdatedStore.updateUnreadCount(by: lID, userID: self.userID, count: count, type: .conversation, shouldSave: false)
        }
    }

    func updateCounterSync(plus: Bool, with labelID: String, context: NSManagedObjectContext) {
        let offset = plus ? 1 : -1
        // Message Count
        let unreadCount: Int = lastUpdatedStore.unreadCount(by: labelID, userID: self.userID, type: .singleMessage)
        var count = unreadCount + offset
        if count < 0 {
            count = 0
        }
        lastUpdatedStore.updateUnreadCount(by: labelID, userID: self.userID, count: count, type: .singleMessage, shouldSave: true)

        // Conversation Count
        let conversationUnreadCount: Int = lastUpdatedStore.unreadCount(by: labelID, userID: self.userID, type: .conversation)
        var conversationCount = conversationUnreadCount + offset
        if conversationCount < 0 {
            conversationCount = 0
        }
        lastUpdatedStore.updateUnreadCount(by: labelID, userID: self.userID, count: count, type: .conversation, shouldSave: true)
    }
}

// MARK: - label related functions
extension CacheService {
    func addNewLabel(serverReponse: [String: Any], completion: (() -> Void)?) {
        context.perform {
            do {
                var response = serverReponse
                response["UserID"] = self.userID
                try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: response, in: self.context)
                if let error = self.context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
            completion?()
        }
    }
    
    func updateLabel(serverReponse: [String: Any], completion: (() -> Void)?) {
        context.perform {
            do {
                var response = serverReponse
                response["UserID"] = self.userID
                if response["ParentID"] == nil {
                    response["ParentID"] = ""
                }
                try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: response, in: self.context)
                if let error = self.context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func updateLabel(_ label: Label, name: String, color: String, completion: (() -> Void)?) {
        context.perform {
            if let labelToUpdate = try? self.context.existingObject(with: label.objectID) as? Label {
                labelToUpdate.name = name
                labelToUpdate.color = color
                if let err = self.context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(err)")
                }
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    func deleteLabel(_ label: Label, completion: (() -> Void)?) {
        context.perform {
            if let labelToDelete = try? self.context.existingObject(with: label.objectID) {
                self.context.delete(labelToDelete)
                if let err = self.context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(err)")
                }
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func deleteLabels(objectIDs: [NSManagedObjectID], completion: (() -> Void)?) {
        context.perform {
            for id in objectIDs {
                guard let label = try? self.context.existingObject(with: id) else {
                    continue
                }
                self.context.delete(label)
            }
            if let err = self.context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(err)")
            }
        }
        DispatchQueue.main.async {
            completion?()
        }
    }
}

// MARK: - contact related functions
extension CacheService {
    func addNewContact(serverReponse: [[String: Any]], shouldFixName: Bool = false, completion: (([Contact]?, NSError?) -> Void)?) {
        context.perform {
            do {
                if let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                   fromJSONArray: serverReponse,
                                                                   in: self.context) as? [Contact] {
                    contacts.forEach { (c) in
                        c.userID = self.userID
                        if shouldFixName {
                            _ = c.fixName(force: true)
                        }
                        if let emails = c.emails.allObjects as? [Email] {
                            emails.forEach { (e) in
                                e.userID = self.userID
                            }
                        }
                    }
                    if let error = self.context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(error)")
                        completion?(nil, error)
                    } else {
                        completion?(contacts, nil)
                    }
                }
            } catch {
                PMLog.D("error: \(error)")
                completion?(nil, error as NSError)
            }
        }
    }

    func updateContact(contactID: String, cardsJson: [String: Any], completion: ((Result<[Contact], NSError>) -> Void)?) {
        context.perform {
            do {
                // remove all emailID associated with the current contact in the core data
                // since the new data will be added to the core data (parse from response)
                if let originalContact = Contact.contactForContactID(contactID, inManagedObjectContext: self.context) {
                    if let emailObjects = originalContact.emails.allObjects as? [Email] {
                        for emailObject in emailObjects {
                            self.context.delete(emailObject)
                        }
                    }
                }

                if let newContact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName, fromJSONDictionary: cardsJson, in: self.context) as? Contact {
                    newContact.needsRebuild = true
                    if let err = self.context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(err)")
                    } else {
                        completion?(.success([newContact]))
                    }
                }
            } catch {
                PMLog.D("error: \(error)")
                completion?(.failure(error as NSError))
            }
        }
    }

    func deleteContact(by contactID: String, completion: ((NSError?) -> Void)?) {
        context.perform {
            var err: NSError?
            if let contact = Contact.contactForContactID(contactID, inManagedObjectContext: self.context) {
                self.context.delete(contact)
            }
            if let error = self.context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
                err = error
            }
            completion?(err)
        }
    }

    func updateContactDetail(serverResponse: [String: Any], completion: ((Contact?, NSError?) -> Void)?) {
        context.perform {
            do {
                if let contact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName, fromJSONDictionary: serverResponse, in: self.context) as? Contact {
                    contact.isDownloaded = true
                    _ = contact.fixName(force: true)
                    if let error = self.context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                        completion?(nil, error)
                    } else {
                        completion?(contact, nil)
                    }
                } else {
                    completion?(nil, NSError.unableToParseResponse(serverResponse))
                }
            } catch {
                PMLog.D("error: \(error)")
                completion?(nil, error as NSError)
            }
        }
    }
}