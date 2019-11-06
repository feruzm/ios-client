//
//  FeedPageVC.swift
//  Commun
//
//  Created by Maxim Prigozhenkov on 15/03/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import UIKit
import CyberSwift
import RxSwift
import RxDataSources
import ESPullToRefresh

class FeedPageVC: PostsViewController {
    
    // MARK: - Properties
    var headerView: UIView! // for parallax
    var lastContentOffset: CGFloat = 0.0
    // MARK: - Outlets
    @IBOutlet weak var floatView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var changeFeedTypeButton: UIButton!
    @IBOutlet weak var _tableView: UITableView!
    @IBOutlet weak var topFloatConstraint: NSLayoutConstraint!

    override var tableView: UITableView! {
        get {return _tableView}
        set {_tableView = newValue}
    }
    
    @IBOutlet weak var userAvatarImage: UIImageView!
    
    override func setUp() {
        super.setUp()

        // avatarImage
        userAvatarImage
            .observeCurrentUserAvatar()
            .disposed(by: disposeBag)
        
        userAvatarImage.addTapToViewer()
        userAvatarImage.observeCurrentUserAvatar()
            .disposed(by: disposeBag)
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.estimatedRowHeight = UITableView.automaticDimension
        // dismiss keyboard when dragging
        tableView.keyboardDismissMode = .onDrag

        tableView.rx.willBeginDragging.subscribe({ _ in
            self.lastContentOffset = self.tableView.contentOffset.y
        }).disposed(by: disposeBag)

        tableView.rx.contentOffset.subscribe {
            guard let offset = $0.element else { return }

            var needAnimation = false
            var newConstraint: CGFloat = 0.0
            var inset: CGFloat = 0.0
            let lastOffset: CGFloat = self.lastContentOffset
            if lastOffset > offset.y || offset.y <= 0  {
                needAnimation = self.topFloatConstraint.constant <= 0
                newConstraint = 0.0
                inset = self.floatView.frame.size.height
            } else if lastOffset < offset.y {
                let position = -self.floatView.frame.size.height
                needAnimation = self.topFloatConstraint.constant >= position
                newConstraint = position
                inset = 0.0
            }

            if needAnimation {
                self.view.layoutIfNeeded()
                self.topFloatConstraint.constant = newConstraint
                self.tableView.contentInset.top = inset
                self.tableView.scrollIndicatorInsets.top = self.tableView.contentInset.top
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    self.view.layoutIfNeeded()
                })
            }

        }.disposed(by: disposeBag)
    }
    
    override func filterChanged(filter: PostsListFetcher.Filter) {
        super.filterChanged(filter: filter)
        // feedTypeMode
        switch filter.feedTypeMode {
        case .subscriptions:
            self.headerLabel.text = "my Feed".localized().uppercaseFirst
            self.changeFeedTypeButton.setTitle("trending".localized().uppercaseFirst, for: .normal)
        case .new:
            self.headerLabel.text = "trending".localized().uppercaseFirst
            
            self.changeFeedTypeButton.setTitle("my Feed".localized().uppercaseFirst, for: .normal)
        default:
            break
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        let tabBarHeight: CGFloat = 88.0
        let bottomInset: CGFloat = 10.0
        tableView.scrollIndicatorInsets.bottom = tabBarHeight + bottomInset
        tableView.contentInset.bottom = tabBarHeight + bottomInset
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
