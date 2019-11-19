//
//  ProfileController.swift
//  Commun
//
//  Created by Chung Tran on 10/29/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import RxSwift
import CyberSwift

protocol ProfileType: ListItemType {
    var userId: String {get}
    var username: String {get}
    var isSubscribed: Bool? {get set}
    var subscribersCount: UInt64? {get set}
    var identity: String {get}
    var isBeingToggledFollow: Bool? {get set}
}

extension ResponseAPIContentGetProfile: ProfileType {
    var subscribersCount: UInt64? {
        get {
            return subscribers?.usersCount
        }
        set {
            subscribers?.usersCount = newValue
        }
    }
}
extension ResponseAPIContentGetSubscriptionsUser: ProfileType {}
extension ResponseAPIContentResolveProfile: ProfileType {}

protocol ProfileController: class {
    associatedtype Profile: ProfileType
    var disposeBag: DisposeBag {get}
    var followButton: CommunButton {get set}
    var profile: Profile? {get set}
    func setUp(with profile: Profile)
}

extension ProfileController {
    func observeProfileChange() {
        Profile.observeItemChanged()
            .subscribe(onNext: {newProfile in
                self.setUp(with: newProfile)
            })
            .disposed(by: disposeBag)
    }
    
    func toggleFollow() {
        guard profile != nil, let userId = profile?.userId else {return}
        
        let originIsFollowing = profile?.isSubscribed ?? false
        
        // set value
        setIsSubscribed(!originIsFollowing)
        profile?.isBeingToggledFollow = true
        
        // animate
        animateFollow()
        
        // notify changes
        profile!.notifyChanged()
        
        // send request
        NetworkService.shared.triggerFollow(userId, isUnfollow: originIsFollowing)
            .subscribe(onCompleted: { [weak self] in
                // re-enable state
                self?.profile?.isBeingToggledFollow = false
                self?.profile?.notifyChanged()
            }) { [weak self] (error) in
                guard let strongSelf = self else {return}
                // reverse change
                strongSelf.setIsSubscribed(originIsFollowing)
                strongSelf.profile?.isBeingToggledFollow = false
                strongSelf.profile!.notifyChanged()
                
                // show error
                UIApplication.topViewController()?.showError(error)
            }
            .disposed(by: disposeBag)
    }
    
    func setIsSubscribed(_ value: Bool) {
        guard profile != nil,
            value != profile?.isSubscribed
        else {return}
        profile!.isSubscribed = value
        var subscribersCount: UInt64 = (profile!.subscribersCount ?? 0)
        if value == false && subscribersCount == 0 {subscribersCount = 0}
        else {
            if value == true {
                subscribersCount += 1
            }
            else {
                subscribersCount -= 1
            }
        }
        profile!.subscribersCount = subscribersCount
    }
    
    func animateFollow() {
        CATransaction.begin()
        
        let moveDownAnim = CABasicAnimation(keyPath: "transform.scale")
        moveDownAnim.byValue = 1.2
        moveDownAnim.autoreverses = true
        followButton.layer.add(moveDownAnim, forKey: "transform.scale")
        
        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.byValue = -1
        fadeAnim.autoreverses = true
        followButton.layer.add(fadeAnim, forKey: "Fade")
        
        CATransaction.commit()
    }
}
