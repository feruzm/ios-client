//
//  CommentsViewController.swift
//  Commun
//
//  Created by Chung Tran on 11/8/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation
import CyberSwift
import RxSwift

class CommentsViewController: ListViewController<ResponseAPIContentGetComment, CommentCell>, CommentCellDelegate {
    // MARK: - Properties
    lazy var expandedComments = [ResponseAPIContentGetComment]()
    
    // MARK: - Subviews
    override var tableView: UITableView {
        get {
            _tableView
        }
        set {
            _tableView = newValue
        }
    }
    
    lazy var _tableView: UITableView = {
        // Override tableView to fix problem with floating footer in section
        // https://stackoverflow.com/a/32517926
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.configureForAutoLayout()
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewSafeArea(with: tableViewMargin)
        tableView.backgroundColor = .white
        return tableView
    }()
    
    // MARK: Initializers
    init(filter: CommentsListFetcher.Filter) {
        let viewModel = CommentsViewModel(filter: filter)
        super.init(viewModel: viewModel)
    }
    
    init(viewModel: CommentsViewModel) {
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        // setup datasource
        tableView.separatorStyle = .none
        
        // setup long press
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnTableView(_:)))
        tableView.addGestureRecognizer(lpgr)
    }
    
    override func configureCell(with comment: ResponseAPIContentGetComment, indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
        cell.expanded = self.expandedComments.contains(where: {$0.identity == comment.identity})
        cell.setUp(with: comment)
        cell.delegate = self
        return cell
    }
    
    override func bind() {
        super.bind()
        
        // filter
        (viewModel as! CommentsViewModel).filter
            .subscribe(onNext: {[weak self] filter in
                self?.filterChanged(filter: filter)
            })
            .disposed(by: disposeBag)
        
        // forward delegate
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    override func bindItems() {
        viewModel.items
            .map {$0.map {ListSection(model: $0.identity, items: [$0] + ($0.children ?? []))}}
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
//    override func bindItemSelected() {
//        tableView.rx.itemSelected
//            .subscribe(onNext: { (indexPath) in
//                guard let cell = self.tableView.cellForRow(at: indexPath) as? CommentCell,
//                    var comment = cell.comment
//                    else {return}
//                
//                // collapse expanded comment
//                self.expandedComments.removeAll(where: {$0.identity == comment.identity})
//                self.tableView.reloadRows(at: [indexPath], with: .fade)
//                
//                // collapse replies
//                comment.children = []
//                comment.notifyChildrenChanged()
//            })
//            .disposed(by: disposeBag)
//    }
    
    func filterChanged(filter: CommentsListFetcher.Filter) {
        
    }
    
    override func handleLoading() {
        tableView.addLoadingFooterView(
            rowType: PlaceholderNotificationCell.self,
            tag: notificationsLoadingFooterViewTag,
            rowHeight: 88,
            numberOfRows: 1
        )
    }
    
    override func handleListEmpty() {
        let title = "no comments"
        let description = "comments not found"
        tableView.addEmptyPlaceholderFooterView(title: title.localized().uppercaseFirst, description: description.localized().uppercaseFirst)
    }
    
    // MARK: - Actions
    func editComment(_ comment: ResponseAPIContentGetComment) {
        // for overriding
    }
    func replyToComment(_ comment: ResponseAPIContentGetComment) {
        // for overriding
    }
    
    func retrySendingComment(_ comment: ResponseAPIContentGetComment) {
        // for overriding
    }
}