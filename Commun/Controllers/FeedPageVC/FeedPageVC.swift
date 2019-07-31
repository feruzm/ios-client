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
import DZNEmptyDataSet
import RxDataSources

class FeedPageVC: UIViewController {

    var viewModel: FeedPageViewModel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userAvatarImage: UIImageView!
    @IBOutlet weak var segmentioView: Segmentio!
    @IBOutlet weak var sortByTypeButton: UIButton!
    @IBOutlet weak var sortByTimeButton: UIButton!
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!
    
    var dataSource: MyRxTableViewSectionedAnimatedDataSource<PostSection>!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Config viewModel
        viewModel = FeedPageViewModel()
        
        viewModel.loadingHandler = { [weak self] in
            if self?.viewModel.fetcher.reachedTheEnd == true {return}
            self?.tableView.addPostLoadingFooterView()
        }
        
        viewModel.listEndedHandler = { [weak self] in
            self?.tableView.tableFooterView = UIView()
        }
        
        viewModel.fetchNextErrorHandler = {[weak self] error in
            guard let strongSelf = self else {return}
            strongSelf.tableView.addListErrorFooterView(with: #selector(strongSelf.didTapTryAgain(gesture:)), on: strongSelf)
            strongSelf.tableView.reloadData()
        }
        
        navigationController?.navigationBar.barTintColor = .white
        
        // searchBar
        let searchBar = UISearchBar(frame: self.view.bounds)
        searchBar.placeholder = "Search"
        self.navigationItem.titleView = searchBar
        
        let searchField: UITextField = searchBar.value(forKey: "searchField") as! UITextField
        searchField.backgroundColor = #colorLiteral(red: 0.9529411765, green: 0.9607843137, blue: 0.9803921569, alpha: 1)
        
        // avatarImage
        userAvatarImage
            .observeCurrentUserAvatar()
            .disposed(by: disposeBag)
        
        userAvatarImage.addTapToViewer()
        
        // tableView
        dataSource = MyRxTableViewSectionedAnimatedDataSource<PostSection>(
            configureCell: { dataSource, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "PostCardCell", for: indexPath) as! PostCardCell
                cell.setUp(with: item)
                
                if indexPath.row == self.viewModel.items.value.count - 2 {
                    self.viewModel.fetchNext()
                }
                
                return cell
            }
        )
        
        tableView.register(UINib(nibName: "PostCardCell", bundle: nil), forCellReuseIdentifier: "PostCardCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.addPostLoadingFooterView()
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        // Segmentio update
        segmentioView.setup(content: [SegmentioItem(title: "My Feed".localized(), image: nil), SegmentioItem(title: "Trending".localized(), image: nil)],
                            style: SegmentioStyle.onlyLabel,
                            options: SegmentioOptions.default)
        segmentioView.valueDidChange = {_, index in
            self.viewModel.feedTypeMode.accept(index == 0 ? .byUser : .community)
            
            // if feed is my feed, then sort by time
            if index == 0 {
                self.viewModel.feedType.accept(.timeDesc)
            }
        }
        
        // fire first filter
        segmentioView.selectedSegmentioIndex = 1
        
        // dismiss keyboard when dragging
        tableView.keyboardDismissMode = .onDrag
        
        // bind ui
        bindUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction func postButtonDidTouch(_ sender: Any) {
        let editorVC = controllerContainer.resolve(EditorPageVC.self)
        let nav = UINavigationController(rootViewController: editorVC!)
        present(nav, animated: true, completion: nil)
    }
    
    @IBAction func photoButtonDidTouch(_ sender: Any) {
        let editorVC = controllerContainer.resolve(EditorPageVC.self)
        let nav = UINavigationController(rootViewController: editorVC!)
        present(nav, animated: true) {
            editorVC?.cameraButtonTap()
        }
    }
    
    @IBAction func sortByTypeButtonDidTouch(_ sender: Any) {
        var options = FeedSortMode.allCases
        
        if viewModel.feedTypeMode.value == .byUser {
            options.removeAll(where: {$0 == .popular})
        }
        
        showActionSheet(actions: options.map { mode in
            UIAlertAction(title: mode.toString(), style: .default, handler: { (_) in
                self.viewModel.feedType.accept(mode)
            })
        })

    }
    
    @IBAction func sortByTimeButtonDidTouch(_ sender: Any) {
        showActionSheet(actions: FeedTimeFrameMode.allCases.map { mode in
            UIAlertAction(title: mode.toString(), style: .default, handler: { (_) in
                self.viewModel.sortType.accept(mode)
            })
        })
    }
    
    @objc func refresh() {
        viewModel.reload()
    }
    
    @objc func didTapTryAgain(gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
            let text = label.text else {return}
        
        let tryAgainRange = (text as NSString).range(of: "Try again".localized())
        if gesture.didTapAttributedTextInLabel(label: label, inRange: tryAgainRange) {
            self.viewModel.fetchNext()
        }
    }
}
