//
//  EditorPageVC+Actions.swift
//  Commun
//
//  Created by Maxim Prigozhenkov on 03/04/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import UIKit
import CyberSwift
import RxSwift
import MBProgressHUD
import TLPhotoPicker

extension EditorPageVC {
    
    @IBAction func cameraButtonTap() {
        let pickerVC = CustomTLPhotosPickerVC.singleImage
        self.present(pickerVC, animated: true, completion: nil)
        
        pickerVC.rx.didSelectAssets
            .filter {($0.count > 0) && ($0.first?.fullResolutionImage != nil)}
            .map {$0.first!.fullResolutionImage!}
            .subscribe(onNext: {image in
                self.imageView.image = image
                pickerVC.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
            // Upload image
            
    }
    
    @IBAction func sendPostButtonTap() {
        guard let viewModel = viewModel else {return}
        self.view.endEditing(true)
        viewModel.sendPost(with: titleTextView.text, text: contentTextView.text, image: self.imageView.image)
            .do(onSubscribe: {
                self.navigationController?.showIndetermineHudWithMessage("sending post".localized().uppercaseFirst)
            })
            .flatMap { (transactionId, userId, permlink) -> Single<(userId: String, permlink: String)> in
                guard let id = transactionId,
                    let userId = userId,
                    let permlink = permlink else {
                        return .error(ErrorAPI.responseUnsuccessful(message: "post not found".localized().uppercaseFirst))
                }
                
                self.navigationController?.showIndetermineHudWithMessage("wait for transaction".localized().uppercaseFirst)
                
                return NetworkService.shared.waitForTransactionWith(id: id)
                    .andThen(Single<(userId: String, permlink: String)>.just((userId: userId, permlink: permlink)))
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (userId, permlink) in
                self.navigationController?.hideHud()
                // if editing post
                if var post = self.viewModel?.postForEdit {
                    post.content.title = self.titleTextView.text
                    post.content.body.full = self.contentTextView.text
                    if let imageURL = self.viewModel?.embeds.first(where: {($0["type"] as? String) == "photo"})?["url"] as? String,
                        let embeded = post.content.embeds.first,
                        embeded.type == "photo" {
                        post.content.embeds[0].result?.url = imageURL
                    }
                    post.notifyChanged()
                    self.dismiss(animated: true, completion: nil)
                } else {
                    // show post page
                    let postPageVC = controllerContainer.resolve(PostPageVC.self)!
                    postPageVC.viewModel.permlink = permlink
                    postPageVC.viewModel.userId = userId
                    var viewControllers = self.navigationController!.viewControllers
                    viewControllers[0] = postPageVC
                    self.navigationController?.setViewControllers(viewControllers, animated: true)
                }
            }, onError: { (error) in
                self.navigationController?.hideHud()
                
                if let error = error as? ErrorAPI {
                    switch error {
                    case .responseUnsuccessful(message: "post not found".localized().uppercaseFirst):
                        self.dismiss(animated: true, completion: nil)
                        break
                    case .blockchain(message: let message):
                        self.showAlert(title: "error".localized().uppercaseFirst, message: message)
                        break
                    default:
                        break
                    }
                }
                
                self.showError(error)
                
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func closeButtonDidTouch(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func removeImageButton(_ sender: Any) {
        imageView.image = nil
        viewModel?.addImage(with: nil)
    }
    
}
