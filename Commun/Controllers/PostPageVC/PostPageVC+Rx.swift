//
//  PostPageVC+Rx.swift
//  Commun
//
//  Created by Maxim Prigozhenkov on 21/03/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import UIKit
import CyberSwift
import RxCocoa
import RxSwift

extension PostPageVC {
    
    func bindUI() {
        // Observe post
        bindPost()
        
        // Observe comments
        bindComments()
        
        // Observe commentForm
        bindCommentForm()
    }
    
    func bindPost() {
        // scrollView
        self.tableView.rx.willDragDown
            .map {$0 ? 0: 56}
            .distinctUntilChanged()
            .subscribe(onNext: {height in
                UIView.animate(withDuration: 0.25, animations: {
                    self.navigationBarHeightConstraint.constant = CGFloat(height)
                    self.view.layoutIfNeeded()
                })
            })
            .disposed(by: disposeBag)
        
        viewModel.post
            .subscribe(onNext: {post in
                if let post = post {
                    // Time ago & community
                    self.comunityNameLabel.isHidden = false
                    self.timeAgoLabel.isHidden = false
                    self.byUserLabel.isHidden = false
                    self.communityAvatarImageView.isHidden = false
                    
                    self.communityAvatarImageView.setAvatar(urlString: post.community.avatarUrl, namePlaceHolder: post.community.communityName ?? post.community.communityId)
                    self.comunityNameLabel.text = post.community.communityName ?? post.community.communityId
                    self.timeAgoLabel.text = Date.timeAgo(string: post.meta.creationTime)
                    self.byUserLabel.text = post.author?.username ?? post.author?.userId ?? ""
                    
                    // commentForm
                    if self.replyingComment == nil {
                        self.commentForm.parentAuthor = post.contentId.userId
                        self.commentForm.parentPermlink = post.contentId.permlink
                    }
                } else {
                    self.comunityNameLabel.isHidden = true
                    self.timeAgoLabel.isHidden = true
                    self.byUserLabel.isHidden = true
                    self.communityAvatarImageView.isHidden = true
                }
                
                
                
                // Create tableHeaderView
                if self.headerView == nil {
                    self.createHeaderView()
                }
                self.headerView.setUp(with: post)
            })
            .disposed(by: disposeBag)
        
        // more button
        let nonNilPost = viewModel.post.filter {$0 != nil}
            .map {$0!}
        
        nonNilPost
            .take(1)
            .asSingle()
            .flatMap {NetworkService.shared.markPostAsRead(permlink: $0.contentId.permlink)}
            .subscribe(onSuccess: {_ in
                Logger.log(message: "Marked post as read", event: .severe)
            })
            .disposed(by: disposeBag)
        
        moreButton.rx.tap
            .withLatestFrom(nonNilPost)
            .subscribe(onNext: {_ in
                guard let headerView = self.tableView.tableHeaderView as? PostHeaderView else {return}
                headerView.openMorePostActions()
            })
            .disposed(by: disposeBag)
    }
    
    func bindComments() {
        viewModel.items
            .map {[CommentSection(model: "", items: $0)]}
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.items
            .subscribe(onNext: {_ in
                self.expandedIndexes = []
            })
            .disposed(by: disposeBag)
    }
    
    func bindCommentForm() {
        commentForm.commentDidSend
            .subscribe(onNext: { [weak self] (_) in
                if (self?.replyingComment != nil) {
                    self?.replyingComment = nil
                }
                
                // update post
                self?.headerView.postDidComment()
                
                #warning("Reload table for testing only")
                self?.viewModel.reload()
            })
            .disposed(by: disposeBag)
        
        commentForm.commentDidFailedToSend
            .subscribe(onNext: { [weak self] (error) in
                self?.view.endEditing(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.showError(error)
                }
            })
            .disposed(by: disposeBag)
    }
}
