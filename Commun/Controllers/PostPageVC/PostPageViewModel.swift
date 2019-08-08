//
//  PostPageViewModel.swift
//  Commun
//
//  Created by Maxim Prigozhenkov on 21/03/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CyberSwift

class PostPageViewModel: ListViewModelType {
    // MARK: - type
    struct GroupedComment: CustomStringConvertible {
        var comment: ResponseAPIContentGetComment
        var replies = [GroupedComment]()
        
        var description: String {
            return "Comment: \"\(comment.content.body.full!)\", Childs: \"\(replies)\""
        }
    }
    
    // MARK: - Handlers
    var loadingHandler: (() -> Void)?
    var listEndedHandler: (() -> Void)?
    var fetchNextErrorHandler: ((Error) -> Void)?
    var fetchNextCompleted: (() -> Void)?
    
    // MARK: - Inputs
    var postForRequest: ResponseAPIContentGetPost?
    var permlink: String?
    var userId: String?
    
    // MARK: - Objects
    let post = BehaviorRelay<ResponseAPIContentGetPost?>(value: nil)
    let comments = BehaviorRelay<[ResponseAPIContentGetComment]>(value: [])
    
    let disposeBag = DisposeBag()
    let fetcher = CommentsFetcher()
    
    // MARK: - Methods
    func loadPost() {
        let permLink = postForRequest?.contentId.permlink ?? permlink ?? ""
        let userId = postForRequest?.contentId.userId ?? self.userId ?? ""
        
        // Bind post
        NetworkService.shared.getPost(withPermLink: permLink,
                                      forUser: userId)
            .catchError({ (error) -> Single<ResponseAPIContentGetPost> in
                if let post = self.postForRequest {
                    return .just(post)
                }
                throw error
            })
            .asObservable()
            .bind(to: post)
            .disposed(by: disposeBag)
        
        // Configure fetcher
        fetcher.permlink = permLink
        fetcher.userId = userId
    }
    
    func fetchNext() {
        fetcher.fetchNext()
            .do(onSubscribed: {
                self.loadingHandler?()
            })
            .catchError { (error) -> Single<[ResponseAPIContentGetComment]> in
                self.fetchNextErrorHandler?(error)
                return .just([])
            }
            .subscribe(onSuccess: {[weak self] (list) in
                guard let strongSelf = self else {return}
                
                guard list.count > 0 else {
                    strongSelf.listEndedHandler?()
                    return
                }
                
                // get unique items
                var newList = list.filter {!strongSelf.comments.value.contains($0)}
                guard newList.count > 0 else {return}
                
                // add last
                newList = strongSelf.comments.value + newList
                
                // sort
                newList = strongSelf.sortComments(newList)
                
                // resign
                strongSelf.comments.accept(newList)
                strongSelf.fetchNextCompleted?()
            })
            .disposed(by: disposeBag)
    }
    
    @objc func reload() {
        comments.accept([])
        fetcher.reset()
        fetchNext()
    }
    
    func sortComments(_ comments: [ResponseAPIContentGetComment]) -> [ResponseAPIContentGetComment] {
        guard comments.count > 0 else {return []}
        
        // result array
        let result = comments.filter {$0.parent.comment == nil}
            .reduce([GroupedComment]()) { (result, comment) -> [GroupedComment] in
                return result + [GroupedComment(comment: comment, replies: getChildForComment(comment, in: comments))]
        }
        
        print(result)
        
        return comments
    }
    
    var maxNestedLevel = 6
    
    func getChildForComment(_ comment: ResponseAPIContentGetComment, in source: [ResponseAPIContentGetComment]) -> [GroupedComment] {
        
        var result = [GroupedComment]()
        
        // filter child
        let childComments = source
            .filter {$0.parent.comment?.contentId?.permlink == comment.contentId.permlink && $0.parent.comment?.contentId?.userId == comment.contentId.userId}
        
        if childComments.count > 0 {
            // append child
            result = childComments.reduce([GroupedComment](), { (result, comment) -> [GroupedComment] in
                return result + [GroupedComment(comment: comment, replies: getChildForComment(comment, in: source))]
            })
        }
        
        return result
    }
    
}
