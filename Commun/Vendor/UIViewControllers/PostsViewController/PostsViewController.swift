//
//  PostsViewController.swift
//  Commun
//
//  Created by Chung Tran on 10/22/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import UIKit
import CyberSwift

class PostsViewController: ListViewController<ResponseAPIContentGetPost, PostCell>, PostCellDelegate {
    // MARK: - Properties
    var posts: [ResponseAPIContentGetPost] {viewModel.items.value}
    
    // MARK: - Initializers
    init(filter: PostsListFetcher.Filter = PostsListFetcher.Filter(type: .subscriptions, sortBy: .time, userId: Config.currentUser?.id), prefetch: Bool = true) {
        let viewModel = PostsViewModel(filter: filter, prefetch: prefetch)
        super.init(viewModel: viewModel)
    }
    
    init(viewModel: PostsViewModel) {
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Custom Functions
    override func setUp() {
        super.setUp()
                
        // setup datasource
        tableView.separatorStyle = .none
    }
    
    override func registerCell() {
        tableView.register(BasicPostCell.self, forCellReuseIdentifier: "BasicPostCell")
        tableView.register(ArticlePostCell.self, forCellReuseIdentifier: "ArticlePostCell")
    }
    
    override func configureCell(with post: ResponseAPIContentGetPost, indexPath: IndexPath) -> UITableViewCell {
        let cell: PostCell
        switch post.document?.attributes?.type {
        case "article":
            cell = self.tableView.dequeueReusableCell(withIdentifier: "ArticlePostCell") as! ArticlePostCell
            cell.setUp(with: post)
        case "basic":
            cell = self.tableView.dequeueReusableCell(withIdentifier: "BasicPostCell") as! BasicPostCell
            cell.setUp(with: post)
        default:
            return UITableViewCell()
        }
        
        cell.delegate = self
        return cell
    }
    
    override func bind() {
        super.bind()
        // filter
        (viewModel as! PostsViewModel).filter
            .subscribe(onNext: {[weak self] filter in
                self?.filterChanged(filter: filter)
            })
            .disposed(by: disposeBag)
        
        // forward delegate
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    override func handleLoading() {
        tableView.addPostLoadingFooterView()
    }
    
    override func handleListEmpty() {
        let title = "no post"
        let description = "posts not found"
        
        tableView.addEmptyPlaceholderFooterView(title: title.localized().uppercaseFirst, description: description.localized().uppercaseFirst, buttonLabel: "reload".localized().uppercaseFirst + "?") {
            self.viewModel.reload()
        }
    }
    
    func openFilterVC() {
        guard let viewModel = viewModel as? PostsViewModel else {return}
        // Create FiltersVC
        let vc = PostsFilterVC(filter: viewModel.filter.value)
        
        vc.completion = { filter in
            viewModel.filter.accept(self.modifyFilter(filter: filter))
        }
        
        let nc = SwipeNavigationController(rootViewController: vc)
        nc.transitioningDelegate = vc
        nc.modalPresentationStyle = .custom
//        nc.makeTransparent()
        
        present(nc, animated: true, completion: {
//            nc.isNavigationBarHidden = true
        })
    }
    
    func modifyFilter(filter: PostsListFetcher.Filter) -> PostsListFetcher.Filter {
        return filter
    }
    
    func filterChanged(filter: PostsListFetcher.Filter) {
        
    }
}

extension PostsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let post = itemAtIndexPath(indexPath),
            let height = viewModel.rowHeights[post.identity]
        else {return UITableView.automaticDimension}
        return height
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let post = itemAtIndexPath(indexPath)
        else {return}
        
        // record post view
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if tableView.isCellVisible(indexPath: indexPath) &&
                self.itemAtIndexPath(indexPath)?.identity == post.identity &&
                !RestAPIManager.instance.markedAsViewedPosts.contains(post.identity)
            {
                post.markAsViewed().disposed(by: self.disposeBag)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard var post = itemAtIndexPath(indexPath) else {return}
        
        // cache height
        viewModel.rowHeights[post.identity] = cell.bounds.height
        
        // hide donation buttons when cell was removed
        if !tableView.isCellVisible(indexPath: indexPath), post.showDonationButtons == true {
            post.showDonationButtons = false
            post.notifyChanged()
        }
    }
}
