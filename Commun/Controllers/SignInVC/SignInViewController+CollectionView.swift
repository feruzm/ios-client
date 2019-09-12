//
//  SignInViewController+CollectionView.swift
//  Commun
//
//  Created by Chung Tran on 27/06/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import QRCodeReaderViewController

extension SignInViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SignInSelectionCell", for: indexPath) as! SignInSelectionCell
        
        configureCell(cell: cell,
                      text: selection[indexPath.row],
                      selected: selected == indexPath.row)
        
        return cell
    }
    
    func configureCell(cell: SignInSelectionCell, text: String, selected: Bool) {
        let label = cell.methodLabel
        label?.text = text
        
        label?.backgroundColor = selected ? #colorLiteral(red: 0.9529411765, green: 0.9607843137, blue: 0.9803921569, alpha: 1) : #colorLiteral(red: 0.8971592784, green: 0.9046500325, blue: 0.9282500148, alpha: 1)
        label?.textColor = selected ? #colorLiteral(red: 0.6062102914, green: 0.6253217459, blue: 0.6361377239, alpha: 1): #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectMethod(index: indexPath.row)
    }
    
    func selectMethod(index: Int) {
        if selected == index {return}
        selected = index
        collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
        switch index {
        case 0:
            qrContainerView.isHidden = false
            loginPasswordContainerView.isHidden = true
            addQrCodeReader()
        default:
            qrContainerView.isHidden = true
            loginPasswordContainerView.isHidden = false
            qrReaderVC?.remove()
        }
    }
    
    func addQrCodeReader() {
        // qrcode reader
        let reader = QRCodeReader(metadataObjectTypes: [AVMetadataObject.ObjectType.qr])
        qrReaderVC = QRCodeReaderViewController(cancelButtonTitle: nil, codeReader: reader, startScanningAtLoad: true, showSwitchCameraButton: true, showTorchButton: true)
        var results = [String]()
        reader.setCompletionWith {[weak self] (string) in
            guard let string = string, !results.contains(string) else {return}
            print(string)
            if string.matches("^[a-z1-5]{12}\\ [0-9A-Za-z]{51}$") {
                let splitedString = string.split(separator: " ")
                let userId = splitedString[0]
                let activeKey = splitedString[1]
                self?.viewModel.qrCode.accept((login: String(userId), key: String(activeKey)))
            } else {
                self?.showErrorWithLocalizedMessage("This QrCode is not valid")
            }
            results.append(string)
        }
        add(qrReaderVC, to: qrCodeReaderView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = selection[indexPath.row].size(withAttributes: [
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)
            ])
        size.width += 32
        size.height += 32*Config.heightRatio
        return size
    }
}
