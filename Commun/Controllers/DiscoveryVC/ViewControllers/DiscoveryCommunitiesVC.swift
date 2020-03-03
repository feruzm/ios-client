//
//  DiscoveryCommunitiesVC.swift
//  Commun
//
//  Created by Chung Tran on 2/18/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation
import RxSwift

class DiscoveryCommunitiesVC: CommunitiesVC {
    override var listLoadingStateObservable: Observable<ListFetcherState> {
        let viewModel = self.viewModel as! CommunitiesViewModel
        return Observable.merge(
            viewModel.state.filter {_ in viewModel.searchVM.isQueryEmpty},
            viewModel.searchVM.state.filter {_ in !viewModel.searchVM.isQueryEmpty}
        )
            .do(onNext: { (state) in
                print(viewModel.searchVM.state.value, viewModel.state.value, state)
            })
    }
    
    init(prefetch: Bool) {
        super.init(type: .all, prefetch: prefetch)
        defer {
            showShadowWhenScrollUp = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindItems() {
        let viewModel = self.viewModel as! CommunitiesViewModel
        Observable.merge(
            viewModel.items.filter {_ in viewModel.searchVM.isQueryEmpty},
            viewModel.searchVM.items
                .filter {_ in !viewModel.searchVM.isQueryEmpty}
                .map{$0.compactMap{$0.communityValue}}
        )
            .map {$0.count > 0 ? [ListSection(model: "", items: $0)] : []}
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    override func handleListEmpty() {
        let title = "no result".localized().uppercaseFirst
        let description = "try to look for something else".localized().uppercaseFirst
        tableView.addEmptyPlaceholderFooterView(emoji: "😿", title: title, description: description)
    }
    
    // MARK: - Search manager
    func searchBarIsSearchingWithQuery(_ query: String) {
        (viewModel as! CommunitiesViewModel).searchVM.query = query
        (viewModel as! CommunitiesViewModel).searchVM.reload(clearResult: false)
    }
    
    func searchBarDidCancelSearching() {
        (viewModel as! CommunitiesViewModel).searchVM.query = nil
        viewModel.items.accept(viewModel.items.value)
        viewModel.state.accept(.loading(false))
    }
}
