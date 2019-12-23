//
//  SubscriptionsViewModel.swift
//  Commun
//
//  Created by Chung Tran on 10/29/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation
import CyberSwift

class SubscriptionsViewModel: ListViewModel<ResponseAPIContentGetSubscriptionsItem> {
    let type: GetSubscriptionsType
    init(userId: String?, type: GetSubscriptionsType) {
        var userId = userId
        if userId == nil {
            userId = Config.currentUser?.id ?? ""
        }
        let fetcher = SubscriptionsListFetcher(userId: userId!, type: type)
        self.type = type
        super.init(fetcher: fetcher)
        
        defer {
            fetchNext()
        }
    }
    
    override func observeItemDeleted() {
        ResponseAPIContentGetSubscriptionsUser.observeItemDeleted()
            .subscribe(onNext: { (deletedUser) in
                self.deleteItem(ResponseAPIContentGetSubscriptionsItem.user(deletedUser))
            })
            .disposed(by: disposeBag)
        
        ResponseAPIContentGetCommunity.observeItemDeleted()
            .subscribe(onNext: { (deletedCommunity) in
                self.deleteItem(ResponseAPIContentGetSubscriptionsItem.community(deletedCommunity))
            })
            .disposed(by: disposeBag)
    }
    
    override func observeItemChange() {
        ResponseAPIContentGetSubscriptionsUser.observeItemChanged()
            .subscribe(onNext: { (newItem) in
                self.updateItem(ResponseAPIContentGetSubscriptionsItem.user(newItem))
            })
            .disposed(by: disposeBag)
        
        ResponseAPIContentGetCommunity.observeItemChanged()
            .subscribe(onNext: {newCommunity in
                self.updateItem(ResponseAPIContentGetSubscriptionsItem.community(newCommunity))
            })
            .disposed(by: disposeBag)
    }
}