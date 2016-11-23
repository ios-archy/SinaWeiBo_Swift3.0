//
//  WBDemoViewController.swift
//  传智微博
//
//  Created by apple on 16/6/29.
//  Copyright © 2016年 itcast. All rights reserved.
//

import UIKit

class WBDemoViewController: WBBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置标题
        title = "第 \(navigationController?.childViewControllers.count ?? 0) 个"
    }
    
    // MARK: - 监听方法
    /// 继续 PUSH 一个新的控制器
    @objc fileprivate func showNext() {
        
        let vc = WBDemoViewController()
        
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension WBDemoViewController {
    
    /// 重写父类方法
    override func setupTableView() {
        super.setupTableView()
        
        // 设置右侧的控制器
        navItem.rightBarButtonItem = UIBarButtonItem(title: "下一个", target: self, action: #selector(showNext))
    }
}
