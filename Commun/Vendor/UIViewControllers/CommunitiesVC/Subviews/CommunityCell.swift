//
//  CommunityCell.swift
//  Commun
//
//  Created by Chung Tran on 11/6/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation
import CyberSwift

class CommunityCell: SubsItemCell, ListItemCellType {
    var joinButton: CommunButton {
        get {
            return actionButton
        }
        set {
            actionButton = newValue
        }
    }
    
    var community: ResponseAPIContentGetCommunity?
    weak var delegate: CommunityCellDelegate?
    
    func setUp(with community: ResponseAPIContentGetCommunity) {
        self.community = community
        avatarImageView.setAvatar(urlString: community.avatarUrl)
        
        let attributedText = NSMutableAttributedString()
            .text(community.name, size: 15, weight: .semibold)
            .text("\n")
            .text(String(format: NSLocalizedString("%d followers", comment: ""), (community.subscribersCount ?? 0)) + " • " + String(format: NSLocalizedString("%d posts", comment: ""), (community.postsCount ?? 0)), size: 12, weight: .semibold, color: .appGrayColor)
            .withParagraphStyle(lineSpacing: 3)
        contentLabel.attributedText = attributedText
        
        // joinButton
        let joined = community.isSubscribed ?? false
        joinButton.backgroundColor = joined ? .appLightGrayColor : .appMainColor
        joinButton.setTitleColor(joined ? .appMainColor: .appWhiteColor, for: .normal)
        joinButton.setTitle((joined ? "following" : "follow").localized().uppercaseFirst, for: .normal)
        joinButton.isEnabled = !(community.isBeingJoined ?? false)
    }
    
    override func actionButtonDidTouch() {
        guard let community = community else {return}
        joinButton.animate {
            self.delegate?.buttonFollowDidTouch(community: community)
        }
    }
}
