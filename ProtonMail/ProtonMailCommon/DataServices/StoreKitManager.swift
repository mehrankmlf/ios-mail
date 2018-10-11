//
//  StoreKitManager.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 21/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import StoreKit
import AwaitKit

class StoreKitManager: NSObject {
    static var `default` = StoreKitManager()
    private override init() {
        super.init()
    }
    
    private var productIds = Set([ServicePlan.plus.storeKitProductId!])
    private var availableProducts: [SKProduct] = []
    private var request: SKProductsRequest!
    
    private var successCompletion: (()->Void)?
    private var deferredCompletion: (()->Void)?
    private var errorCompletion: (Error)->Void = { error in
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            let alert = UIAlertController(title: LocalString._error_occured, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._general_ok_action, style: .cancel, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    internal func subscribeToPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }
    
    internal func updateAvailableProductsList() {
        request = SKProductsRequest(productIdentifiers: self.productIds)
        request.delegate = self
        request.start()
    }
    
    internal func priceLabelForProduct(id: String) -> (NSDecimalNumber, Locale)? {
        guard let product = self.availableProducts.first(where: { $0.productIdentifier == id }) else {
            return nil
        }
        return (product.price, product.priceLocale)
    }
    
    internal func readyToPurchaseProduct(id productId: String? = nil,
                          username: String? = nil) -> Bool
    {
        let newestTransaction = SKPaymentQueue.default().transactions.filter {
                (productId == nil || $0.payment.productIdentifier == productId!)
                && (username == nil || $0.payment.applicationUsername == self.hash(username: username!))
        }.reduce(nil) { (previous, next) -> SKPaymentTransaction? in
                guard let previous = previous else { return next }
                return previous.transactionDate < next.transactionDate ? next : previous
        }
        guard newestTransaction == nil else {
            return false // got unfinished transaction - do not allow new purchases
        }
        return true
    }
    
    internal func purchaseProduct(withId id: String,
                                  username: String,
                                  successCompletion: @escaping ()->Void,
                                  errorCompletion: @escaping (Error)->Void,
                                  deferredCompletion: @escaping ()->Void)
    {
        guard let product = self.availableProducts.first(where: { $0.productIdentifier == id }) else {
            errorCompletion(Errors.unavailableProduct)
            return
        }
        
        self.successCompletion = successCompletion
        self.errorCompletion = errorCompletion
        self.deferredCompletion = deferredCompletion
        
        let payment = SKMutablePayment(product: product)
        payment.quantity = 1
        payment.applicationUsername = self.hash(username: username)
        SKPaymentQueue.default().add(payment)
    }
    
    enum Errors: LocalizedError {
        case unavailableProduct
        case recieptLost
        case haveTransactionOfAnotherUser
        case alreadyPurchasedPlanDoesNotMatchBackend
        case sandboxReceipt
        
        var errorDescription: String? {
            switch self {
            case .unavailableProduct: return LocalString._unavailable_product
            case .recieptLost: return LocalString._reciept_lost
            case .haveTransactionOfAnotherUser: return LocalString._another_user_transaction
            case .alreadyPurchasedPlanDoesNotMatchBackend: return LocalString._backend_mismatch
            case .sandboxReceipt: return LocalString._sandbox_receipt
            }
        }
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.availableProducts = response.products
    }
    
    private func hash(username: String) -> String {
        return username.sha256
    }
}

extension StoreKitManager: SKPaymentTransactionObserver {
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        DispatchQueue.global().async {
            transactions.forEach(self.process)
        }
    }
    
    // FIXME: break down into multiple methods
    private func process(_ transaction: SKPaymentTransaction) {
        switch transaction.transactionState {
        case .failed:
            let error = transaction.error! as NSError
            switch error {
            case SKError.paymentCancelled: break // no need to do anything
            default: self.errorCompletion(error)
            }
            SKPaymentQueue.default().finishTransaction(transaction)
            
        case .purchased:
            guard let hashedUsername = transaction.payment.applicationUsername,
                let currentUsername = sharedUserDataService.username,
                hashedUsername == self.hash(username: currentUsername) else
            {
                self.errorCompletion(Errors.haveTransactionOfAnotherUser)
                return
            }
            
            guard let receiptUrl = Bundle.main.appStoreReceiptURL,
                !receiptUrl.lastPathComponent.contains("sandbox") else
            {
                self.errorCompletion(Errors.sandboxReceipt)
                SKPaymentQueue.default().finishTransaction(transaction)
                return
            }
            
            guard let reciept = try? Data(contentsOf: receiptUrl).base64EncodedString() else {
                self.errorCompletion(Errors.recieptLost)
                SKPaymentQueue.default().finishTransaction(transaction)
                return
            }
            do {
                guard let plan = ServicePlan(storeKitProductId: transaction.payment.productIdentifier),
                    let details = plan.fetchDetails(),
                    let planId = details.iD else
                {
                    throw Errors.alreadyPurchasedPlanDoesNotMatchBackend
                }
                let serverUpdateApi = PostRecieptRequest(reciept: reciept, andActivatePlanWithId: planId)
                let serverUpdateRes = try await(serverUpdateApi.run())
                if let newSubscription = serverUpdateRes.newSubscription {
                    ServicePlanDataService.shared.currentSubscription = newSubscription
                }
                self.successCompletion?()
                SKPaymentQueue.default().finishTransaction(transaction)
            } catch let error {
                switch (error as NSError).code {
                case 22101:
                    // Amount mismatch - try report only credits without activating the plan
                    do {
                        let serverUpdateApi = PostCreditRequest(reciept: reciept)
                        let _ = try await(serverUpdateApi.run())
                        self.successCompletion?()
                        SKPaymentQueue.default().finishTransaction(transaction)
                    } catch let error {
                        if (error as NSError).code == 22915 { // Apple payment already registered
                            SKPaymentQueue.default().finishTransaction(transaction)
                        } else {
                            self.errorCompletion(error)
                        }
                    }
//                case 22914: //TODO:: need to handle this properly
//                    SKPaymentQueue.default().finishTransaction(transaction)
//                    self.successCompletion?()
                default:
                    self.errorCompletion(error)
                }
            }
        case .deferred, .purchasing:
            self.deferredCompletion?()
            
        case .restored:
            break // never happens in our flow
        }
    }
}