//
//  SDWebImageLoadDelegate.swift
//  GearUIExample
//
//  Created by 谌启亮 on 2021/8/19.
//  Copyright © 2021 Tencent. All rights reserved.
//

import UIKit
import GearUI
import SDWebImage

extension SDWebImageCombinedOperation: GUImageLoadOperation {
}

class SDWebImageLoadDelegate: NSObject, GUImageLoadDelegate {
    func loadImage(from url: URL!, completed completedBlock: GUImageLoadCompletedBlock!) -> GUImageLoadOperation! {
        return SDWebImageManager.shared.loadImage(with: url, options: [.handleCookies, .continueInBackground, .retryFailed], context: nil, progress: nil) { (image, _, error, _, _, _) in
            completedBlock(error, image, false)
        }
    }
}

