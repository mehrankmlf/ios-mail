//
//  MessageDetailRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

/// Navigation Bar buttons
fileprivate let labelNavBarButtonIdentifier = "UINavigationItem.topLabelButton"
fileprivate let folderNavBarButtonIdentifier = "UINavigationItem.topFolderButton"
fileprivate let trashNavBarButtonIdentifier = "UINavigationItem.topTrashButton"
fileprivate let moreNavBarButtonIdentifier = "UINavigationItem.topMoreButton"
fileprivate let backToInboxNavBarButtonIdentifier = LocalString._menu_inbox_title

/// Reply/Forward buttons
fileprivate let replyButtonIdentifier = "MessageContainerViewController.replyButton"
fileprivate let replyAllButtonIdentifier = "MessageContainerViewController.replyAllButton"
fileprivate let forwardButtonIdentifier = "MessageContainerViewController.forwardButton"

/*
 MessageRobot class contains actions and verifications for Message detail view funcctionality.
 */
class MessageRobot {
    
    func addMessageToFolder(_ folderName: String) -> InboxRobot {
        openFoldersModal()
            .selectFolder(folderName)
            .clickApplyButtonAndReturnToInbox()
    }
    
    func assignLabelToMessage(_ folderName: String) -> MessageRobot {
        openLabelsModal()
            .selectFolder(folderName)
            .clickLabelApplyButton()
    }
    
    func createFolder(_ folderName: String) -> MoveToFolderRobot {
        openFoldersModal()
            .clickAddFolder()
            .typeFolderName(folderName)
            .tapKeyboardDoneButton()
            .clickCreateFolderButton()
    }
    
    func createLabel(_ folderName: String) -> MoveToFolderRobot {
        openLabelsModal()
            .clickAddLabel()
            .typeFolderName(folderName)
            .tapKeyboardDoneButton()
            .clickCreateFolderButton()
    }

    func moveToTrash() -> InboxRobot {
        Element.wait.forButtonWithIdentifier(trashNavBarButtonIdentifier, file: #file, line: #line).tap()
        return InboxRobot()
    }
    
    func navigateBackToInbox() -> InboxRobot {
        Element.wait.forButtonWithIdentifier(backToInboxNavBarButtonIdentifier, file: #file, line: #line).tap()
        return InboxRobot()
    }

    func openFoldersModal() -> MoveToFolderRobot {
        Element.wait.forButtonWithIdentifier(folderNavBarButtonIdentifier, file: #file, line: #line).tap()
        return MoveToFolderRobot()
    }
    
    func openLabelsModal() -> MoveToFolderRobot {
        Element.wait.forButtonWithIdentifier(labelNavBarButtonIdentifier, file: #file, line: #line).tap()
        return MoveToFolderRobot()
    }
    
    func moreOptions() -> MessageMoreOptions {
        Element.wait.forButtonWithIdentifier(moreNavBarButtonIdentifier, file: #file, line: #line).tap()
        return MessageMoreOptions()
    }

    func reply() -> ComposerRobot {
        Element.wait.forButtonWithIdentifier(replyButtonIdentifier, file: #file, line: #line).tap()
        return ComposerRobot()
    }

    func replyAll() -> ComposerRobot {
        Element.wait.forButtonWithIdentifier(replyAllButtonIdentifier, file: #file, line: #line).tap()
        return ComposerRobot()
    }

    func forward() -> ComposerRobot {
        Element.wait.forButtonWithIdentifier(forwardButtonIdentifier, file: #file, line: #line).tap()
        return ComposerRobot()
    }

    class MessageMoreOptions {

        func viewHeaders() {
            
        }
    }
    
    internal class MoveToFolderRobot: MoveToFolderRobotInterface {

        override func clickAddFolder() -> AddNewFolderRobot {
            super.clickAddFolder()
            return AddNewFolderRobot()
        }
        
        override func clickAddLabel() -> AddNewFolderRobot {
            super.clickAddLabel()
            return AddNewFolderRobot()
        }
        
        override func selectFolder(_ folderName: String) -> MoveToFolderRobot {
            super.selectFolder(folderName)
            return MoveToFolderRobot()
        }
        
        override func clickApplyButtonAndReturnToInbox() -> InboxRobot {
            super.clickApplyButtonAndReturnToInbox()
            return InboxRobot()
        }
        
        override func clickLabelApplyButton() -> MessageRobot {
            super.clickLabelApplyButton()
            return MessageRobot()
        }
    }
    
    class AddNewFolderRobot: MoveToFolderRobotInterface {

        override func typeFolderName(_ folderName: String) -> AddNewFolderRobot {
            super.typeFolderName(folderName)
            return self
        }
        
        override func selectFolderColorByIndex(_ index: Int) -> AddNewFolderRobot {
            super.selectFolderColorByIndex(index)
            return self
        }
        
        override func clickCreateFolderButton() -> MoveToFolderRobot {
            super.clickCreateFolderButton()
            return MoveToFolderRobot()
        }
        
        override func tapKeyboardDoneButton() -> AddNewFolderRobot {
            super.tapKeyboardDoneButton()
            return AddNewFolderRobot()
        }
    }

    class Verify {
        func messageContainsAttachment() {}

        func quotedHeaderShown() {}

        func attachmentsNotAdded() {}

        func attachmentsAdded() {}

        func messageWebViewContainerShown() {}
    }
}
