//
//  BasicEditorVC+Draft.swift
//  Commun
//
//  Created by Chung Tran on 10/15/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation

extension BasicEditorVC {
    // MARK: - Draft
    override func shouldSaveDraft() -> Bool {
        viewModel.postForEdit == nil && (!contentTextView.text.trimmed.isEmpty || !titleTextView.text.trimmed.isEmpty || _viewModel.attachment.value != nil)
    }
    
    override var hasDraft: Bool {
        return super.hasDraft ||
            UserDefaults.standard.dictionaryRepresentation().keys.contains(attachmentDraftKey)
    }
    
    override func saveDraft() {
        var draft = [Data]()
        if let attachment = self._viewModel.attachment.value {
            if let data = try? JSONEncoder().encode(attachment) {
                draft.append(data)
            }
        }
        
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: self.attachmentDraftKey)
        }
        
        super.saveDraft()
    }
    
    override func getDraft() {
        // show hud
        showIndetermineHudWithMessage("retrieving attachments".localized().uppercaseFirst)
        
        // retrieve draft on another thread
        DispatchQueue(label: "pasting").async {
            guard let data = UserDefaults.standard.data(forKey: self.attachmentDraftKey),
                let draft = try? JSONDecoder().decode([Data].self, from: data)
            else {
                    DispatchQueue.main.async {
                        self.hideHud()
                    }
                    return
            }
            for data in draft {
                DispatchQueue.main.sync {
                    if let attachment = try? JSONDecoder().decode(TextAttachment.self, from: data) {
                        self._viewModel.attachment.accept(attachment)
                    }
                }
            }
            DispatchQueue.main.sync {
                super.getDraft()
            }
        }
    }
    
    override func removeDraft() {
       UserDefaults.standard.removeObject(forKey: attachmentDraftKey)
       super.removeDraft()
    }
}
