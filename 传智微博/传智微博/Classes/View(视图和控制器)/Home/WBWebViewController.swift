//
//  WBWebViewController.swift
//  传智微博
//
//  Created by apple on 16/7/10.
//  Copyright © 2016年 itcast. All rights reserved.
//

import UIKit

/// 网页控制器
class WBWebViewController: WBBaseViewController {

    fileprivate lazy var webView = UIWebView(frame: UIScreen.main.bounds)
    
    /// 要加载的 URL 字符串
    var urlString: String? {
        didSet {
            
            guard let urlString = urlString,
                let url = URL(string: urlString)
                else {
                    return
            }
            
            webView.loadRequest(URLRequest(url: url))
        }
    }
}

extension WBWebViewController {
    
    override func setupTableView() {
        
        // 设置标题
        navItem.title = "网页"
        
        // 设置 webView
        view.insertSubview(webView, belowSubview: navigationBar)
        
        webView.backgroundColor = UIColor.white
        
        // 设置 contentInset
        webView.scrollView.contentInset.top = navigationBar.bounds.height
    }
}
