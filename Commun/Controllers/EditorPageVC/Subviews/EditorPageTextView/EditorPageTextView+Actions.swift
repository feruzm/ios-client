//
//  EditorPageTextView+Actions.swift
//  Commun
//
//  Created by Chung Tran on 9/3/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation

extension EditorPageTextView {
    // MARK: - Methods
    private func attach(image: UIImage, urlString: String? = nil, description: String? = nil) {
        // Insert Attachment
        let attachment = textStorage.imageAttachment(from: image, urlString: urlString, description: description, into: self)
        let imageAS = NSAttributedString(attachment: attachment)
        
        // insert
        if var selectedTextRange = selectedTextRange {
            var location = offset(from: beginningOfDocument, to: selectedTextRange.start)
            
            // insert an endline character
            if location > 0,
                textStorage.attributedSubstring(from: NSMakeRange(location - 1, 1)).string != "\n" {
                textStorage.insert(NSAttributedString.separator, at: location)
                location += 1
                
                let newStart = position(from: selectedTextRange.start, offset: 1)!
                let newEnd = position(from: selectedTextRange.end, offset: 1)!
                selectedTextRange = textRange(from: newStart, to: newEnd)!
            }
            
            replace(selectedTextRange, withText: "")
            location = offset(from: beginningOfDocument, to: selectedTextRange.start)
            textStorage.insert(imageAS, at: location)
            textStorage.insert(NSAttributedString.separator, at: location+1)
        }
            // append
        else {
            textStorage.append(NSAttributedString.separator)
            textStorage.append(imageAS)
            textStorage.addAttributes(typingAttributes, range: NSMakeRange(textStorage.length - 1, 1))
        }
    }
    
    func addImage(_ image: UIImage? = nil, urlString: String? = nil, description: String? = nil) {
        
        // set image
        if let image = image {
            attach(image: image, urlString: urlString, description: description)
        } else if let urlString = urlString,
            let url = URL(string: urlString) {
            
            NetworkService.shared.downloadImage(url)
                .do(onSubscribe: {
                    self.parentViewController?.navigationController?
                        .showIndetermineHudWithMessage("loading".localized().uppercaseFirst)
                })
                .catchErrorJustReturn(UIImage(named: "image-not-available")!)
                .subscribe(
                    onSuccess: { [weak self] (image) in
                        guard let strongSelf = self else {return}
                        strongSelf.parentViewController?.navigationController?.hideHud()
                        strongSelf.attach(image: image, urlString: urlString, description: description)
                    },
                    onError: {[weak self] error in
                        self?.parentViewController?.navigationController?.hideHud()
                        self?.parentViewController?.showError(error)
                    }
                )
                .disposed(by: bag)
        } else {
            parentViewController?.showGeneralError()
        }
    }
    
    func parseText(_ string: String) {
        // Plain string
        var attributedText = NSAttributedString(string: string)
        
        // Parse data
        if let jsonData = string.data(using: .utf8),
            let block = try? JSONDecoder().decode(ContentBlock.self, from: jsonData) {
            attributedText = block.toAttributedString(currentAttributes: typingAttributes)
        }
        
        // Asign raw value first
        self.attributedText = attributedText
        
        // Parse medias
        self.textStorage.parseContent(into: self)
            .do(onSubscribe: {
                self.parentViewController?.navigationController?
                    .showIndetermineHudWithMessage("loading".localized().uppercaseFirst)
            })
            .subscribe(onCompleted: { [weak self] in
                self?.parentViewController?.navigationController?.hideHud()
            }) { [weak self] (error) in
                self?.parentViewController?.navigationController?.showError(error)
            }
            .disposed(by: bag)
    }
}
