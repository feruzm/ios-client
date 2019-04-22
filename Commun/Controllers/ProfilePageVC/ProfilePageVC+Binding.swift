//
//  ProfilePageVC+Binding.swift
//  Commun
//
//  Created by Chung Tran on 19/04/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import UIKit
import CyberSwift
import Action
import RxSwift
import TLPhotoPicker

extension ProfilePageVC {
    enum ImageType {
        case cover, avatar
    }
    
    func bindViewModel() {
        let profile = viewModel.profile.asDriver()
        
        // End refreshing
        profile.map {_ in false}
            .drive(tableView.refreshControl!.rx.isRefreshing)
            .disposed(by: bag)
        
        // Bind state
        let isProfileMissing = profile.map {$0 == nil}
        
        isProfileMissing
            .drive(tableView.rx.isHidden)
            .disposed(by: bag)
        
        isProfileMissing
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: bag)
        
        // Got profile
        let nonNilProfile = profile.filter {$0 != nil}.map {$0!}
        
        nonNilProfile
            .drive(self.rx.profile)
            .disposed(by: bag)
        
        // Bind items
        viewModel.items.skip(1)
            .map { items -> [AnyObject?] in
                if items.count == 0 {
                    return [nil]
                }
                return items as [AnyObject?]
            }
            .bind(to: tableView.rx.items) {table, index, element in
                if element == nil {
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: "ProfilePageEmptyCell") as! ProfilePageEmptyCell
                    cell.setUp(with: self.viewModel.segmentedItem.value)
                    return cell
                }
                
                if let post = element as? ResponseAPIContentGetPost {
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: "PostCardCell") as! PostCardCell
                    cell.delegate = self
                    cell.post = post
                    cell.setupFromPost(post)
                    return cell
                }
                
                if let comment = element as? ResponseAPIContentGetComment {
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
                    cell.delegate = self
                    cell.setupFromComment(comment)
                    return cell
                }
                
                fatalError("Unknown cell type")
            }
            .disposed(by: bag)
        
        // OnItemSelected
        tableView.rx.itemSelected
            .subscribe(onNext: {indexPath in
                let cell = self.tableView.cellForRow(at: indexPath)
                switch cell {
                case is PostCardCell:
                    if let postPageVC = controllerContainer.resolve(PostPageVC.self),
                        let post = self.viewModel.items.value[indexPath.row] as? ResponseAPIContentGetPost{
                        postPageVC.viewModel.postForRequest = post
                        self.present(postPageVC, animated: true, completion: nil)
                    } else {
                        self.showAlert(title: "Error", message: "Something went wrong")
                    }
                    break
                case is CommentCell:
                    #warning("Tap a comment")
                    break
                default:
                    break
                }
            })
            .disposed(by: bag)
        
        // Image selectors
        coverSelectButton.rx.action = onUpdateCover()
//        avatarSelectButton.rx.action = onUpdate(.avatar)
        
        // Bind image
        viewModel.avatarImage
            .asDriver(onErrorJustReturn: nil)
            .filter {$0 != nil}
            .drive(userAvatarImage.rx.image)
            .disposed(by: bag)
        
        viewModel.coverImage
            .asDriver(onErrorJustReturn: nil)
            .filter {$0 != nil}
            .drive(userCoverImage.rx.image)
            .disposed(by: bag)
    }
    
    // MARK: - Actions
    // Image selection
    func onUpdateCover() -> CocoaAction {
        return Action {_ in
            let vc = TLPhotosPickerViewController()
            var configure = TLPhotosPickerConfigure()
            configure.singleSelectedMode = true
            configure.allowedLivePhotos = false
            configure.allowedVideo = false
            configure.allowedVideoRecording = false
            configure.mediaType = .image
            vc.configure = configure
            self.present(vc, animated: true, completion: nil)
            
            return vc.rx.didSelectAssets
                .filter {$0.count > 0 && $0[0].type == TLPHAsset.AssetType.photo && $0[0].fullResolutionImage != nil}
                .map {$0[0].fullResolutionImage!}
                .do(onNext: {image in
                    #warning("drag and drop cover")
                    self.viewModel.coverImage.accept(image)
                    #warning("Send image change request to server")
                })
                .map {_ in}
        }
    }
    
    // Copy referral button
    #warning("Action for copy referral button")
}
