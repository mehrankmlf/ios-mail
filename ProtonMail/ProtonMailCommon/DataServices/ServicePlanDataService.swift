//
//  ServicePlanDataService.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 17/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import AwaitKit

protocol ServicePlanDataStorage {
    var servicePlansDetails: [ServicePlanDetails]? { get set }
    var isIAPAvailable: Bool { get set }
    var defaultPlanDetails: ServicePlanDetails? { get set }
    var currentSubscription: Subscription? { get set }
}

class ServicePlanDataService: NSObject {
    typealias CompletionHandler = ()->Void
    
    static var shared = ServicePlanDataService(localStorage: userCachedStatus)
    private let localStorage: ServicePlanDataStorage

    internal init(localStorage: ServicePlanDataStorage) {
        self.localStorage = localStorage
        self.allPlanDetails = localStorage.servicePlansDetails ?? []
        self.isIAPAvailable = localStorage.isIAPAvailable
        self.defaultPlanDetails = localStorage.defaultPlanDetails
        self.currentSubscription = localStorage.currentSubscription
        super.init()
    }
    
    private var allPlanDetails: [ServicePlanDetails] {
        willSet { userCachedStatus.servicePlansDetails = newValue }
    }
    
    var isIAPAvailable: Bool {
        willSet { userCachedStatus.isIAPAvailable = newValue }
    }
    
    var defaultPlanDetails: ServicePlanDetails? {
        willSet { userCachedStatus.defaultPlanDetails = newValue }
    }
    
    @objc dynamic var currentSubscription: Subscription? {
        willSet { userCachedStatus.currentSubscription = newValue }
    }
    
    internal func detailsOfServicePlan(named name: String) -> ServicePlanDetails? {
        return self.allPlanDetails.first(where: { $0.name == name }) ?? self.defaultPlanDetails
    }
    
    
    //tempory data
    var proceedTier54 : Decimal = Decimal(0)
    
}

extension ServicePlanDataService {
    internal func updateServicePlans(completion: CompletionHandler? = nil) {
        async {
            let statusApi = GetIAPStatusRequest()
            let statusRes = try await(statusApi.run())
            self.isIAPAvailable = statusRes.isAvailable ?? false
            
            let servicePlanApi = GetServicePlansRequest()
            let servicePlanRes = try await(servicePlanApi.run())
            self.allPlanDetails = servicePlanRes.availableServicePlans ?? []
            
            let defaultServicePlanApi = GetDefaultServicePlanRequest()
            let defaultServicePlanRes = try await(defaultServicePlanApi.run())
            self.defaultPlanDetails = defaultServicePlanRes.defaultMailPlan

            completion?()
        }.catch { _ in
            completion?()
        }
    }
    
    internal func updatePaymentMethods(completion: CompletionHandler? = nil) {
        async {
            let paymentMethodsApi = GetPaymentMethodsRequest()
            let paymentMethodsRes = try await(paymentMethodsApi.run())
            self.currentSubscription?.paymentMethods = paymentMethodsRes.methods
            completion?()
        }.catch { _ in
            completion?()
        }
    }
    
    internal func updateTier() {
        async {
            //TODO:: workaround, later we need move this into a dynamic way
            if let productId = ServicePlan.plus.storeKitProductId,
                let price = StoreKitManager.default.priceLabelForProduct(id: productId),
                let currency = price.1.currencyCode,
                let countryCode = (price.1 as NSLocale).object(forKey: .countryCode) as? String {
                let proceedRequest = GetAppleTier(currency: currency, country: countryCode)
                let proceed = try await(proceedRequest.run())
                self.proceedTier54 = proceed.proceed
            }
        }.catch { _ in
            self.proceedTier54 = Decimal(0)
        }
    }
    
    internal func updateCurrentSubscription(completion: CompletionHandler? = nil) {
        self.updateServicePlans()
        async {
            let subscriptionApi = GetSubscriptionRequest()
            let subscriptionRes = try await(subscriptionApi.run())
            self.currentSubscription = subscriptionRes.subscription
            self.updatePaymentMethods()
            completion?()
        }.catch { error in
            if (error as NSError).code == 22110 { // no subscription stands for free/default plan
                self.currentSubscription = Subscription(start: nil, end: nil, planDetails: nil, paymentMethods: nil)
            }
            completion?()
        }.finally {
            self.updateTier()
        }

    }
}