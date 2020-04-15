//
//  FeedPageVC+PostCardCellDelegate.swift
//  Commun
//
//  Created by Maxim Prigozhenkov on 19/03/2019.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import UIKit
import RxSwift
import CyberSwift

protocol PostController: class {
    var disposeBag: DisposeBag {get}
    var voteContainerView: VoteContainerView {get set}
    var post: ResponseAPIContentGetPost? {get set}
    func setUp(with post: ResponseAPIContentGetPost)
}

extension PostController {
    func observePostChange() {
        ResponseAPIContentGetPost.observeItemChanged()
            .filter {$0.identity == self.post?.identity}
            .subscribe(onNext: {newPost in
                guard let newPost = self.post?.newUpdatedItem(from: newPost) else {return}
                self.setUp(with: newPost)
            })
            .disposed(by: disposeBag)
    }
    
    func openMorePostActions() {
        guard let topController = UIApplication.topViewController(),
            let post = post
        else {return}
        
        var actions = [CommunActionSheet.Action]()
        
        actions.append(
            CommunActionSheet.Action(
                title: "view in Explorer".localized().uppercaseFirst,
                handle: { (topController as? BaseViewController)?.load(url: "https://explorer.cyberway.io/trx/\(post.meta.trxId ?? "")") }
            )
        )

        actions.append(
            CommunActionSheet.Action(title: "share".localized().uppercaseFirst, icon: UIImage(named: "share"), handle: {
                self.sharePost()
            })
        )

        if post.author?.userId != Config.currentUser?.id {
            actions.append(
                CommunActionSheet.Action(title: "send report".localized().uppercaseFirst,
                                         icon: UIImage(named: "report"),
                                         tintColor: UIColor(hexString: "#ED2C5B")!,
                                         handle: {
                                            self.reportPost()
                })
            )
        } else {
            actions.append(
                CommunActionSheet.Action(title: "edit".localized().uppercaseFirst,
                                         icon: UIImage(named: "edit"),
                                         handle: {
                                            self.editPost()
                })
            )
            
            actions.append(
                CommunActionSheet.Action(title: "delete".localized().uppercaseFirst,
                                         icon: UIImage(named: "delete"),
                                         tintColor: UIColor(hexString: "#ED2C5B")!,
                                         handle: {
                                            self.deletePost()
                })
            )
        }
        
        // headerView for actionSheet
        let headerView = PostMetaView(frame: .zero)
        headerView.isUserNameTappable = false
        
        topController.showCommunActionSheet(headerView: headerView, actions: actions) {
            headerView.setUp(post: post)
        }
    }
    
    // MARK: - Voting
    
    func upVote() {
        guard let post = post else {return}
        if post.contentId.userId == Config.currentUser?.id {
            UIApplication.topViewController()?.showAlert(title: "error".localized().uppercaseFirst, message: "can't cancel vote on own publication".localized().uppercaseFirst)
            return
        }
        // animate
        voteContainerView.animateUpVote {
            BlockchainManager.instance.upvoteMessage(post)
                .subscribe { (error) in
                    UIApplication.topViewController()?.showError(error)
                }
                .disposed(by: self.disposeBag)
        }
    }
    
    func downVote() {
        guard let post = post else {return}
        if post.contentId.userId == Config.currentUser?.id {
            UIApplication.topViewController()?.showAlert(title: "error".localized().uppercaseFirst, message: "can't cancel vote on own publication".localized().uppercaseFirst)
            return
        }
        // animate
        voteContainerView.animateDownVote {
            BlockchainManager.instance.downvoteMessage(post)
                .subscribe { (error) in
                    UIApplication.topViewController()?.showError(error)
                }
                .disposed(by: self.disposeBag)
        }
    }
    
    // MARK: - Other actions
    func sharePost() {
        ShareHelper.share(post: post)
    }
    
    func reportPost() {
        guard let post = post else {return}
        let vc = ContentReportVC(content: post)
        let nc = BaseNavigationController(rootViewController: vc)
        
        nc.modalPresentationStyle = .custom
        nc.transitioningDelegate = vc
        UIApplication.topViewController()?
            .present(nc, animated: true, completion: nil)
    }
    
    func deletePost() {
        guard let post = post,
            let topController = UIApplication.topViewController()
        else {return}
        
        topController.showAlert(
            title: "delete".localized().uppercaseFirst,
            message: "do you really want to delete this post".localized().uppercaseFirst + "?",
            buttonTitles: [
                "yes".localized().uppercaseFirst,
                "no".localized().uppercaseFirst],
            highlightedButtonIndex: 1) { (index) in
                if index == 0 {
                    topController.showIndetermineHudWithMessage("deleting post".localized().uppercaseFirst)
                    BlockchainManager.instance.deleteMessage(post)
                        .subscribe(onCompleted: {
                            topController.hideHud()
                        }, onError: { error in
                            topController.hideHud()
                            topController.showError(error)
                        })
                        .disposed(by: self.disposeBag)
                }
            }
    }
    
    func editPost() {
        guard let post = post,
            let topController = UIApplication.topViewController() else {return}
        
        topController.showIndetermineHudWithMessage("loading post".localized().uppercaseFirst)
        // Get full post
        RestAPIManager.instance.loadPost(userId: post.contentId.userId, permlink: post.contentId.permlink, communityId: post.contentId.communityId ?? "")
            .subscribe(onSuccess: {post in
                topController.hideHud()
                if post.document?.attributes?.type == "basic" {
                    let vc = BasicEditorVC(post: post)
                    topController.present(vc, animated: true, completion: nil)
                    return
                }
                
                if post.document?.attributes?.type == "article" {
                    let vc = ArticleEditorVC(post: post)
                    topController.present(vc, animated: true, completion: nil)
                    return
                }
                topController.hideHud()
                topController.showError(CMError.invalidRequest(message: ErrorMessage.unsupportedTypeOfPost.rawValue))
            }, onError: {error in
                topController.hideHud()
                topController.showError(error)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Commented
    func postDidComment() {
        guard post != nil else {return}
        self.post!.stats?.commentsCount += 1
        self.post!.notifyChanged()
    }
}
