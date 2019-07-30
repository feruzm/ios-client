//
//  ResponseAPIContentGetPost.swift
//  Commun
//
//  Created by Chung Tran on 20/05/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import CyberSwift
import RxDataSources

extension ResponseAPIContentGetPost: Equatable, IdentifiableType {
    public static func == (lhs: ResponseAPIContentGetPost, rhs: ResponseAPIContentGetPost) -> Bool {
        return lhs.identity == rhs.identity
    }
    
    public var identity: String {
        return self.contentId.userId + "/" + self.contentId.permlink
    }
    
    public var firstEmbedImageURL: String? {
        let embeds = content.embeds
        if embeds.count > 0,
            let imageURL = embeds[0].result?.thumbnail_url ?? embeds[0].result?.url {
            return imageURL
        }
        return nil
    }
    
    public func notifyChanged() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PostControllerPostDidChangeNotification), object: self)
    }
}
