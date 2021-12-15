//
//  MultiuserManagementTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import ProtonCore_TestingToolkit

class MultiuserManagementTests : BaseTestCase {

    private let loginRobot = LoginRobot()

    func testConnectOnePassAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginTwoPasswordUser(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectOnePassAccount(onePassUser)
            .menuDrawer()
            .accountsList()
            .verify.accountAdded(onePassUser)
    }

    func testConnectTwoPassAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .verify.accountAdded(twoPassUser)
    }

    func testConnectTwoPassAccountWithTwoFa() {
        let onePassUser = testData.onePassUser
        let twoPassUserWith2Fa = testData.twoPassUserWith2Fa
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccountWithTwoFa(twoPassUserWith2Fa)
            .menuDrawer()
            .accountsList()
            .verify.accountAdded(twoPassUserWith2Fa)
    }

    func testConnectOnePassAccountWithTwoFa() {
        let onePassUser = testData.onePassUser
        let onePassUserWith2Fa = testData.onePassUserWith2Fa
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectOnePassAccountWithTwoFa(onePassUserWith2Fa)
            .menuDrawer()
            .accountsList()
            .verify.accountAdded(onePassUserWith2Fa)
    }

    //Remove all account function is no longer available in v4
    func disabletestRemoveAllAccounts() {
        let onePassUser = testData.onePassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .removeAllAccounts()
            .verify.loginScreenIsShown()
    }

    func testLogoutPrimaryAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .logoutPrimaryAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .verify.accountSignedOut(twoPassUser)
    }

    func testLogoutSecondaryAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .logoutSecondaryAccount(onePassUser)
            .closeManageAccounts()
            .menuDrawer()
            .accountsList()
            .verify.accountSignedOut(onePassUser)
    }

    func testRemovePrimaryAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot.loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .logoutPrimaryAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .deleteAccount(twoPassUser)
            .verify.accountRemoved(twoPassUser)
    }

    func testRemoveSecondaryAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .logoutSecondaryAccount(onePassUser)
            .closeManageAccounts()
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .deleteAccount(onePassUser)
            .verify.accountRemoved(onePassUser)
    }

    func testCancelLoginOnTwoFaPrompt() {
        let onePassUser = testData.onePassUser
        let onePassUserWith2Fa = testData.onePassUserWith2Fa
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .cancelLoginOnTwoFaPrompt(onePassUserWith2Fa)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .verify.accountRemoved(onePassUserWith2Fa)
    }

    func testAddTwoFreeAccounts() {
        let twoPassUserWith2Fa = testData.twoPassUserWith2Fa
        let onePassUserWith2Fa = testData.onePassUserWith2Fa
        loginRobot
            .loginTwoPasswordUserWithTwoFA(twoPassUserWith2Fa)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectSecondFreeOnePassAccountWithTwoFa(onePassUserWith2Fa)
            .verify.limitReachedDialogDisplayed()
    }

    func testSwitchAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .switchToAccount(onePassUser)
            .menuDrawer()
            .verify.currentAccount(onePassUser)
    }
}
