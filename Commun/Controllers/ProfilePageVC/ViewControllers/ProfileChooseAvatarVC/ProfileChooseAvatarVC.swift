//
//  ProfileChooseAvatarVC.swift
//  Commun
//
//  Created by Chung Tran on 24/04/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import UIKit
import RxSwift
import Photos
import PhotosUI

class ProfileChooseAvatarVC: UIViewController {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var requestAccessButton: UIButton!
    
    var viewModel = ProfileChooseAvatarViewModel()
    private let bag = DisposeBag()
    
    private let itemsInARow: CGFloat = 4

    override func viewDidLoad() {
        super.viewDidLoad()
        // CollectionView
        collectionView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layoutForCollectionView()
        
        // device rotation
        NotificationCenter.default.rx.notification(Notification.Name("UIDeviceOrientationDidChangeNotification"))
            .subscribe(onNext: { [weak self] (_) in
                guard let strongSelf = self else {return}
                strongSelf.collectionView.collectionViewLayout = strongSelf.layoutForCollectionView()
            })
            .disposed(by: bag)

        // Bind views
        bindUI()
    }
    
    func bindUI() {
        // bind avatar
        viewModel.avatar
            .filter {$0 != nil}
            .map {$0!}
            .bind(to: avatarImageView.rx.image)
            .disposed(by: bag)
        
        // request permission
        viewModel.authorizationStatus
            .bind { status in
                switch status {
                case .authorized:
                    self.requestAccessButton.isHidden = true
                    self.collectionView.isHidden = false
                    self.viewModel.fetchAllImage()
                default:
                    self.requestAccessButton.isHidden = false
                    self.collectionView.isHidden = true
                }
            }
            .disposed(by: bag)
        
        // request button
        requestAccessButton.rx.action = viewModel.onRequestPermission()
        
        // bind assets to collectionView
        self.viewModel.phAssets
            .bind(to: collectionView.rx.items(
                cellIdentifier: "PhotoLibraryCell",
                cellType: PhotoLibraryCell.self))
            { index, asset, cell in
                cell.setUp(with: asset)
            }
            .disposed(by: bag)
        
        // item selected
        self.collectionView.rx.modelSelected(PHAsset.self)
            .subscribe(onNext: {asset in
                let manager = PHImageManager.default()
                let option = PHImageRequestOptions()
                option.isSynchronous = true
                option.deliveryMode = .highQualityFormat
                manager.requestImage(for: asset, targetSize: self.avatarImageView.size, contentMode: .aspectFit, options: option) { (image, _) in
                    #warning("adding zoomable view")
                    self.avatarImageView.image = image
                }
            })
            .disposed(by: bag)
    }
    
    func layoutForCollectionView() -> UICollectionViewFlowLayout {
        let screenWidth = collectionView.bounds.inset(by: collectionView.layoutMargins).width
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInsetReference = .fromSafeArea
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenWidth/itemsInARow, height: screenWidth/itemsInARow)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        return layout
    }

}
