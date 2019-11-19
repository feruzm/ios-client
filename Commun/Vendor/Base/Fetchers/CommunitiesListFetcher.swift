//
//  CommunitiesListFetcher.swift
//  Commun
//
//  Created by Chung Tran on 11/6/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import CyberSwift
import RxSwift

class CommunitiesListFetcher: ListFetcher<ResponseAPIContentGetCommunity> {
    var type: GetCommunitiesType
    var userId: String?
    
    init(type: GetCommunitiesType, userId: String? = nil) {
        self.type = type
        self.userId = userId
    }
    
    override var request: Single<[ResponseAPIContentGetCommunity]> {
        return RestAPIManager.instance.getCommunities(type: .all, userId: userId, offset: Int(offset), limit: Int(limit))
            .map {$0.items}
    }
}
