//
//  NetworkService.swift
//  Commun
//
//  Created by Maxim Prigozhenkov on 19/03/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import RxSwift
import Foundation
import Alamofire
import CyberSwift
import SwifterSwift
import eosswift

class NetworkService: NSObject {
    // MARK: - Properties
    static let shared = NetworkService()
    
    
    // MARK: - Class Functions
//    func connect() {
//        WebSocketManager.instance.connect()
//    }
//    
//    func disconnect() {
//        WebSocketManager.instance.disconnect()
//    }
    
    func loadFeed(_ paginationKey: String?, withSortType sortType: FeedTimeFrameMode = .all, withFeedType type: FeedSortMode = .popular, withFeedTypeMode typeMode: FeedTypeMode = .community, userId: String? = nil) -> Observable<ResponseAPIContentGetFeed> {
        
        return Observable.create({ observer -> Disposable in
            
            RestAPIManager.instance.loadFeed(typeMode: typeMode,
                                             userID: userId ?? Config.currentUser.id,
                                             communityID:               AppProfileType.golos.rawValue,
                                             timeFrameMode:             sortType,
                                             sortMode:                  type,
                                             paginationSequenceKey:     paginationKey,
                                             completion:                { (feed, errorAPI) in
                                                guard errorAPI == nil else {
                                                    Logger.log(message: errorAPI!.caseInfo.message.localized(), event: .error)
                                                    observer.onError(errorAPI!)
                                                    return
                                                }
                                                
                                                if let feed = feed {
                                                    observer.onNext(feed)
                                                }
                                                observer.onCompleted()
            })
            
            return Disposables.create()
        })
        
    }
    
    func getPost(withPermLink permLink: String, forUser user: String) -> Observable<ResponseAPIContentGetPost> {
        return Observable.create({ observer -> Disposable in
            
            RestAPIManager.instance.loadPost(userID:        user,
                                             permlink:      permLink,
                                             completion:    { (post, errorAPI) in
                                                guard errorAPI == nil else {
                                                    Logger.log(message: errorAPI!.caseInfo.message.localized(), event: .error)
                                                    return
                                                }
                                                
                                                if let post = post {
                                                    Logger.log(message: "Response: \n\t\(post)", event: .debug)
                                                    observer.onNext(post)
                                                }
                                                
                                                observer.onCompleted()
            })
            
            return Disposables.create()
        })
    }
    
    func deletePost(permlink: String, refBlockNum:  UInt64) -> Completable {
        guard let currentUserId = Config.currentUser.id else {return .error(ErrorAPI.requestFailed(message: "Current user not found"))}
        return RestAPIManager.instance.rx.deleteMessage(author: currentUserId, permlink: permlink)
            .observeOn(MainScheduler.instance)
    }
    
    func getUserComments(_ paginationKey: String? = nil, nickName: String? = nil) -> Single<ResponseAPIContentGetComments> {
        return Single.create {single in
            RestAPIManager.instance.loadUserComments(nickName: nickName, paginationSequenceKey: paginationKey, completion: { (response, error) in
                guard error == nil else {
                    Logger.log(message: error!.caseInfo.message.localized(), event: .error)
                    single(.error(error!))
                    return
                }
                if let res = response {
                    single(.success(res))
                    return
                }
            })
            return Disposables.create()
        }
    }
    
    func getPostComment(_ paginationKey: String? = nil, withPermLink permLink: String, forUser user: String) -> Single<ResponseAPIContentGetComments> {
        return Single.create{ single in
            RestAPIManager.instance.loadPostComments(nickName:                  user,
                                                     permlink:                  permLink,
                                                     sortMode:                  .timeDesc,
                                                     paginationSequenceKey:     paginationKey,
                                                     completion:                { (response, error) in
                                                        guard error == nil else {
                                                            Logger.log(message: error!.caseInfo.message.localized(), event: .error)
                                                            single(.error(error!))
                                                            return
                                                        }
                                                        
                                                        if let res = response {
                                                            single(.success(res))
                                                            return
                                                        }
            })
            return Disposables.create()
        }
    }
    
    enum SignInError: Error {
        case errorAPI(String)
    }
    
    func signIn(login: String, key: String) -> Observable<String> {
        return Observable.create({ observer -> Disposable in
            RestAPIManager.instance.authorize(userID:               login,
                                              userActiveKey:        key,
                                              responseHandling:     { response in
                                                Config.currentUser.id = login
                                                Config.currentUser.activeKey = key
                                                
                                                Logger.log(message: response.permission, event: .debug)
                                                observer.onNext(response.permission)
                                                observer.onCompleted()
            },
                                              errorHandling:        { errorAPI in
                                                Logger.log(message: errorAPI.caseInfo.message.localized(), event: .error)
                                                observer.onError(SignInError.errorAPI(errorAPI.caseInfo.message.localized()))
            })
            
            return Disposables.create()
        })
    }
    
    func voteMessage(voteType: VoteActionType, messagePermlink: String, messageAuthor: String) -> Completable {
        return RestAPIManager.instance.rx.vote(
                voteType:   voteType,
                author:     messageAuthor,
                permlink:   messagePermlink,
                weight:     voteType == .unvote ? 0 : 1)
            .observeOn(MainScheduler.instance)
    }
    
    // return transactionId
    typealias SendPostCompletion = (transactionId: String?, userId: String?, permlink: String?)
    func sendPost(withTitle title: String, withText text: String, metaData json: String, withTags tags: [String]) -> Single<SendPostCompletion> {
        return RestAPIManager.instance.rx.create(message:             text,
                                                 headline:            title,
                                                 tags:                tags,
                                                 metaData:            json)
            .map({ (transaction) -> SendPostCompletion in
                let any = ((transaction.body?.processed.action_traces.first?.act.data["message_id"])?.jsonValue) as? [String: eosswift.AnyJSONType]
                return SendPostCompletion(transactionId: transaction.body?.transaction_id,
                                          userId: any?["author"]?.jsonValue as? String,
                                          permlink: any?["permlink"]?.jsonValue as? String)
            })
            .observeOn(MainScheduler.instance)
    }
    
    func waitForTransactionWith(id: String) -> Completable {
        return Completable.create {completable in
            RestAPIManager.instance.waitForTransactionWith(id: id) { (error) in
                if error != nil {
                    completable(.error(error!))
                    return
                }
                completable(.completed)
            }
            return Disposables.create()
        }
    }
    
    func sendComment(comment: String, metaData json: String = "", tags: [String], forPostWithPermlink permlink: String) -> Completable {
        return RestAPIManager.instance.rx.create(
            message: comment,
            parentPermlink: permlink,
            tags: tags,
            metaData: json
        )
            .flatMapCompletable({ (transaction) -> Completable in
                #warning("Remove this chaining to use socket in production")
                guard let transactionId = transaction.body?.transaction_id else {
                    return .error(ErrorAPI.responseUnsuccessful(message: "transactionId is missing"))
                }
                return self.waitForTransactionWith(id: transactionId)
            })
        .observeOn(MainScheduler.instance)
    }
    
    func signUp(withPhone phone: String) -> Observable<ResponseAPIRegistrationFirstStep> {
        return Observable.create({ observer -> Disposable in
//            RestAPIManager.instance.firstStep(phone:        phone,
//                                              completion:   { (result, error) in
//                                                guard error == nil else {
//                                                    Logger.log(message: error!.message.localized(), event: .error)
//                                                    
//                                                    if let state = error?.currentState {
//                                                        observer.onNext(ResponseAPIRegistrationFirstStep(code: UInt64(error!.code), strategy: state, nextSmsRetry: ""))
//                                                        observer.onCompleted()
//                                                    }
//                                                    
//                                                    return
//                                                }
// 
//                                                if let result = result {
//                                                    Logger.log(message: "Response: \n\t\(result)", event: .debug)
//                                                    observer.onNext(result)
//                                                }
//                                                
//                                                observer.onCompleted()
//            })
            
            return Disposables.create()
        })
    }
    
//    func resendSmsCode(phone: String) -> Observable<String> {
//        return Observable<String>.create({ observer -> Disposable in
//            let isDebugMode: Bool   =   appBuildConfig == AppBuildConfig.debug
//            
//            RestAPIManager.instance.resendSmsCode(phone:        phone,
//                                                  isDebugMode:  isDebugMode,
//                                                  completion:   { (result, errorAPI) in
//                                                    guard errorAPI == nil else {
//                                                        Logger.log(message: errorAPI!.caseInfo.message.localized(), event: .error)
//                                                        return
//                                                    }
//                                                    
//                                                    if let result = result {
//                                                        Logger.log(message: "Response: \n\t\(result.code)", event: .debug)
//                                                        observer.onNext("\(result.code )")
//                                                    }
//                                                    observer.onCompleted()
//            })
//            return Disposables.create()
//        }).map({ code -> String in
//            return code.md5() ?? ""
//        })
//    }
    
    func setUser(name: String, phone: String) -> Observable<String> {
        return Observable.create({ observer -> Disposable in
//
//            let isDebugMode: Bool   =   appBuildConfig == AppBuildConfig.debug
//
//            RestAPIManager.instance.setUser(name:           name,
//                                            phone:          phone,
//                                            isDebugMode:    isDebugMode,
//                                            completion:     { (result, errorAPI) in
//                                                guard errorAPI == nil else {
//                                                    Logger.log(message: errorAPI!.caseInfo.message.localized(), event: .error)
//                                                    return
//                                                }
//
//                                                if let result = result {
//                                                    Logger.log(message: "Response: \n\t\(result.status)", event: .debug)
//                                                    observer.onNext(result.status)
//                                                }
//
//                                                observer.onCompleted()
//            })
            
            return Disposables.create()
        })
    }
    
    func saveKeys(nickName: String) -> Observable<Bool> {
        return Observable.create({ observer -> Disposable in
            RestAPIManager.instance.toBlockChain(id:                nickName,
                                                 phone:             UserDefaults.standard.value(forKey: Config.registrationUserPhoneKey) as? String ?? "",
                                                 responseHandling:  { result in
                                                    Logger.log(message: "Response: \n\t\(result.description)", event: .debug)
                                                    observer.onNext(result)
                                                    observer.onCompleted()
            },
                                                 errorHandling:     { errorAPI in
                                                    Logger.log(message: errorAPI.caseInfo.message.localized(), event: .error)
            })
            
            return Disposables.create()
        })
    }
    
    
    func getUserProfile(userId: String? = nil) -> Single<ResponseAPIContentGetProfile> {
        return Single<ResponseAPIContentGetProfile>.create { single in
            guard let userNickName = userId ?? Config.currentUser.id else { return Disposables.create() }
            
            RestAPIManager.instance.getProfile(userID:      userNickName,
                                               completion:  { (response, error) in
                                                guard error == nil else {
                                                    Logger.log(message: "Error loadding profile: \(error!)", event: .error)
                                                    single(.error(error!))
                                                    return
                                                }
                                                
                                                if let res = response {
                                                    if (res.userId == Config.currentUser.id) {
                                                        UserDefaults.standard.set(res.personal.avatarUrl, forKey: Config.currentUserAvatarUrlKey)
                                                    }
                                                    single(.success(res))
                                                    return
                                                }
            })
            return Disposables.create()
        }
    }
    
    func getNotifications(fromId: String? = nil, markAsViewed: Bool = true, freshOnly: Bool = false) -> Single<ResponseAPIOnlineNotifyHistory> {
        return Single<ResponseAPIOnlineNotifyHistory>.create {single in
            RestAPIManager.instance.getOnlineNotifyHistory(fromId: fromId, freshOnly: false, completion: { (response, error) in
                guard error == nil else {
                    single(.error(error!))
                    return
                }
                if let res = response {
                    single(.success(res))
                    return
                }
            })
            return Disposables.create()
        }
    }
    
    func getFreshNotifications() -> Single<ResponseAPIOnlineNotifyHistoryFresh> {
        return Single<ResponseAPIOnlineNotifyHistoryFresh>.create {single in
            RestAPIManager.instance.getOnlineNotifyHistoryFresh(completion: { (response, error) in
                guard error == nil else {
                    single(.error(error!))
                    return
                }
                if let res = response {
                    single(.success(res))
                    return
                }
            })
            return Disposables.create()
        }
    }
    
    func markAllAsViewed() -> Single<ResponseAPINotifyMarkAllAsViewed> {
        return Single<ResponseAPINotifyMarkAllAsViewed>.create {single in
            RestAPIManager.instance.notifyMarkAllAsViewed(completion: { (response, error) in
                guard error == nil else {
                    single(.error(error!))
                    return
                }
                if let res = response {
                    single(.success(res))
                    return
                }
            })
            return Disposables.create()
        }
    }
    
    func userVerify(phone: String, code: String) -> Observable<Bool> {
        
        return Observable<String>.create({ observer -> Disposable in
            
//            let isDebugMode: Bool   =   appBuildConfig == AppBuildConfig.debug
//            
//            RestAPIManager.instance.verify(phone:           phone,
//                                           code:            code,
//                                           isDebugMode:     isDebugMode,
//                                           completion:      { (result, errorAPI) in
//                                            guard errorAPI == nil else {
//                                                Logger.log(message: errorAPI!.caseInfo.message.localized(), event: .error)
//                                                return
//                                            }
//                                            
//                                            if let result = result {
//                                                Logger.log(message: "Response: \n\t\(result.status)", event: .debug)
//                                                observer.onNext(result.status)
//                                            }
//                                            
//                                            observer.onCompleted()
//            })
            
            return Disposables.create()
        }).map({ result -> Bool in
            return result == "OK"
        })
        
    }
    
    //  MARK: - Contract `gls.social`
    func uploadImage(_ image: UIImage) -> Single<String> {
        return .create {single in
            DispatchQueue(label: "Uploading queue").async {
                RestAPIManager.instance.posting(image: image, responseHandling: { (url) in
                    return single(.success(url))
                }, errorHandling: { (error) in
                    return single(.error(error))
                })
            }
            
            return Disposables.create()
        }
    }
    
    //  Update updatemeta
    func updateMeta(params: [String: String]) -> Completable {
        return RestAPIManager.instance.rx.update(userProfile: params)
            .flatMapCompletable({ (transaction) -> Completable in
                guard let id = transaction.body?.transaction_id else {return .error(ErrorAPI.responseUnsuccessful(message: "transactionId is missing"))}
                
                // update profile
                if let url = params["profile_image"] {
                    UserDefaults.standard.set(url, forKey: Config.currentUserAvatarUrlKey)
                }
                
                return self.waitForTransactionWith(id: id)
            })
            .observeOn(MainScheduler.instance)
    }
    
    func followUser(_ userToFollow: String) -> Completable {
        return RestAPIManager.instance.rx.follow(userToFollow)
            .flatMapToCompletable()
    }
    
    func unFollowUser(_ userToUnFollow: String) -> Completable {
        return RestAPIManager.instance.rx.follow(userToUnFollow, isUnfollow: true)
            .flatMapToCompletable()
    }
    
    // MARK: - options
    func getOptions() -> Completable {
        return .create {completable in
            RestAPIManager.instance.getOptions(responseHandling: { (options) in
                NotificationSettingType.getOptions(options.notify.show)
                completable(.completed)
            }, errorHandling: { (errorAPI) in
                completable(.error(errorAPI))
            })
            return Disposables.create()
        }
    }
    
    func setBasicOptions(lang: Language) {
        RestAPIManager.instance.setBasicOptions(language: lang.code, nsfwContent: .alwaysAlert, responseHandling: { (result) in

        }) { (errorAPI) in
        }
    }
    
    func setOptions(options: RequestParameterAPI.NoticeOptions, type: NoticeType) -> Completable {
        return .create {completable in
            RestAPIManager.instance.set(options: options, type: type, responseHandling: { (_) in
                completable(.completed)
            }, errorHandling: { (error) in
                completable(.error(error))
            })
            return Disposables.create()
        }
    }
    
    // MARK: - meta
    // meta.recordPostView
    func markPostAsRead(permlink: String) {
        RestAPIManager.instance.recordPostView(permlink: permlink, responseHandling: { (_) in
            Logger.log(message: "Marked post \"\(permlink)\" as read", event: .info)
        }) { (error) in
            Logger.log(message: "Can not make post as read with error: \(error)", event: .error)
        }
    }
}
