//
//  SwipeDownDismissViewController.swift
//  Commun
//
//  Created by Chung Tran on 9/30/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import UIKit

class SwipeDownDismissViewController: UIViewController {
    var panGestureRecognizer: UIPanGestureRecognizer?
    var interactor: SwipeDownInteractor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        interactor = SwipeDownInteractor()
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer!)
    }
    
    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.3

        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        guard let interactor = interactor else {
            return
        }
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.cancel()
        default:
            break
        }
    }
}
