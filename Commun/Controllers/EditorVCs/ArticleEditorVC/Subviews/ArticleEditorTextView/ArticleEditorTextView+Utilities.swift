//
//  EditorPageTextView+Utilities.swift
//  Commun
//
//  Created by Chung Tran on 9/4/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import RxSwift

extension ArticleEditorTextView {
    // MARK: - Attachment helper    
    func canAddAttachment(_ attachment: TextAttachment) -> Bool {
        var embedCount = 1
        var videoCount = attachment.embed?.type == "video" ? 1 : 0
        
        // Count attachments
        textStorage.enumerateAttribute(.attachment, in: NSMakeRange(0, textStorage.length), options: []) { (attr, range, stop) in
            if let attr = attr as? TextAttachment {
                embedCount += 1
                if attr.embed?.type == "video"
                {
                    videoCount += 1
                }
            }
        }
        
        return embedCount <= embedsLimit && videoCount <= videosLimit
    }
    
    func addAttachmentAtSelectedRange(_ attachment: TextAttachment) {
        // check if can add attachment
        if !canAddAttachment(attachment) {
            parentViewController?.showErrorWithMessage("can not add more than".localized().uppercaseFirst + " " + "\(embedsLimit)" + " " + "attachments".localized() + " " + "and" + " " + "\(videosLimit)" + " " + "videos".localized())
            return
        }
        
        // attachmentAS to add
        let attachmentAS = NSMutableAttributedString()
        
        // insert an separator at the beggining of attachment if not exists
        if selectedRange.location > 0,
            textStorage.attributedSubstring(from: NSMakeRange(selectedRange.location - 1, 1)).string != "\n" {
            attachmentAS.append(NSAttributedString.separator)
        }
        
        attachmentAS.append(NSAttributedString(attachment: attachment))
        attachmentAS.append(NSAttributedString.separator)
        attachmentAS.addAttributes(typingAttributes, range: NSMakeRange(0, attachmentAS.length))
        
        // replace
        textStorage.replaceCharacters(in: selectedRange, with: attachmentAS)
        selectedRange = NSMakeRange(selectedRange.location + attachmentAS.length, 0)
    }
    
    func replaceCharacters(in range: NSRange, with attachment: TextAttachment) {
        let attachmentAS = NSAttributedString(attachment: attachment)
        textStorage.replaceCharacters(in: range, with: attachmentAS)
        textStorage.addAttributes(typingAttributes, range: NSMakeRange(range.location, 1))
    }
    
    // MARK: - contextMenu modification
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // if selected attachment
        if selectedAttachment != nil
        {
            if action == #selector(copy(_:)) || action == #selector(cut(_:)) {
                return true
            }
        }
        else {
            if action == #selector(previewAttachment(_:)) {
                return false
            }
        }
        
        if action == #selector(paste(_:)) {
            let pasteBoard = UIPasteboard.general
            if pasteBoard.items.last?["attachment"] != nil { return true }
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    override func copy(_ sender: Any?) {
        if let attachment = selectedAttachment {
            copyAttachment(attachment)
            return
        }
        return super.copy(sender)
    }

    override func cut(_ sender: Any?) {
        if let attachment = selectedAttachment {
            self.copyAttachment(attachment, completion: {
                self.textStorage.replaceCharacters(in: self.selectedRange, with: "")
                self.selectedRange = NSMakeRange(self.selectedRange.location, 0)
            })
            return
        }
        return super.cut(sender)
    }
    
    override func paste(_ sender: Any?) {
        let pasteBoard = UIPasteboard.general
        
        // Paste attachment
        if let data = pasteBoard.items.last?["attachment"] as? Data,
            let attachment = try? JSONDecoder().decode(TextAttachment.self, from: data)
        {
            addAttachmentAtSelectedRange(attachment)
            return
        }
        
        // TODO: Paste html
//        if let html = pasteBoard.items.last?["public.html"] as? String {
//            let htmlData = NSString(string: html).data(using: String.Encoding.unicode.rawValue)
//            let options = [NSAttributedString.DocumentReadingOptionKey.documentType:
//                NSAttributedString.DocumentType.html]
//            if let attributedString = try? NSMutableAttributedString(data: htmlData ?? Data(),
//                                                                  options: options,
//                                                                  documentAttributes: nil) {
//                attributedString.addAttribute(.font, value: defaultFont, range: NSMakeRange(0, attributedString.length))
//                textStorage.replaceCharacters(in: selectedRange, with: attributedString)
//                return
//            }
//        }

        super.paste(sender)
    }
}
