//
//  EditorPageTextView+Attachment.swift
//  Commun
//
//  Created by Chung Tran on 9/6/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import CyberSwift
import RxSwift

extension ArticleEditorTextView {
    var selectedAttachment: TextAttachment? {
        if selectedRange.length == 1,
            let attachment = textStorage.attribute(.attachment, at: selectedRange.location, effectiveRange: nil) as? TextAttachment
        {
            return attachment
        }
        return nil
    }
    
    // MARK: - Methods
    private func addEmbed(_ embed: ResponseAPIFrameGetEmbed) {
        guard let single = embed.toTextAttachmentSingle() else {return}
        
        single
            .do(onSubscribe: {
                self.parentViewController?
                    .showIndetermineHudWithMessage("loading".localized().uppercaseFirst)
            })
            .subscribe(
                onSuccess: { [weak self] (attachment) in
                    guard let strongSelf = self else {return}
                    strongSelf.parentViewController?.hideHud()
                    
                    var attachment = attachment
                    
                    // Add image to attachment
                    strongSelf.add(attachment.localImage!, to: &attachment)
                    
                    // Add attachment
                    strongSelf.addAttachmentAtSelectedRange(attachment)
                },
                onError: {[weak self] error in
                    self?.parentViewController?.hideHud()
                    self?.parentViewController?.showError(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - Link
    func addLink(_ urlString: String, placeholder: String?) {
        // if link has placeholder
        if let placeholder = placeholder,
            !placeholder.isEmpty
        {
            var attrs = typingAttributes
            attrs[.link] = urlString
            let attrStr = NSMutableAttributedString(string: placeholder, attributes: attrs)
            textStorage.replaceCharacters(in: selectedRange, with: attrStr)
            let newSelectedRange = NSMakeRange(selectedRange.location + attrStr.length, 0)
            selectedRange = newSelectedRange
            typingAttributes = defaultTypingAttributes
        }
            // if link is a separated block
        else {
            // detect link type
            NetworkService.shared.getEmbed(url: urlString)
                .do(onSubscribe: {
                    self.parentViewController?
                        .showIndetermineHudWithMessage(
                            "loading".localized().uppercaseFirst)
                })
                .subscribe(onSuccess: {[weak self] embed in
                    self?.parentViewController?.hideHud()
                    self?.addEmbed(embed)
                }, onError: {error in
                    self.parentViewController?.hideHud()
                    self.parentViewController?.showError(error)
                })
                .disposed(by: disposeBag)
            // show
        }
    }
    
    // MARK: - Image
    func addImage(_ image: UIImage? = nil, urlString: String? = nil, description: String? = nil) {
        var embed = try! ResponseAPIFrameGetEmbed(
            blockAttributes: ContentBlockAttributes(
                url: urlString, description: description
            )
        )
        embed.type = "image"
        
        // if image is local image
        if let image = image {
            // Insert Attachment
            var attachment = TextAttachment()
            attachment.embed = embed
            attachment.localImage = image
            
            // Add image to attachment
            add(image, to: &attachment)
            
            // Add attachment
            addAttachmentAtSelectedRange(attachment)
        }
            
        // if image is from link
        else {
            addEmbed(embed)
        }
    }
}
