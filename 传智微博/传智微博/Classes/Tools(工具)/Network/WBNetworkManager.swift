//
//  WBNetworkManager.swift
//  传智微博
//
//  Created by apple on 16/7/2.
//  Copyright © 2016年 itcast. All rights reserved.
//

import UIKit
import AFNetworking

/// Swift 的枚举支持任意数据类型
/// switch / enum 在 OC 中都只是支持整数
/**
 - 如果日常开发中，发现网络请求返回的状态码是 405，不支持的网络请求方法
 - 首先应该查找网路请求方法是否正确
 */
enum WBHTTPMethod {
    case GET
    case POST
}

/// 网络管理工具
class WBNetworkManager: AFHTTPSessionManager {

    /// 静态区／常量／闭包
    /// 在第一次访问时，执行闭包，并且将结果保存在 shared 常量中
    static let shared: WBNetworkManager = {
        
        // 实例化对象
        let instance = WBNetworkManager()
        
        // 设置响应反序列化支持的数据类型
        instance.responseSerializer.acceptableContentTypes?.insert("text/plain")
        
        // 返回对象
        return instance
    }()
    
    /// 用户账户的懒加载属性
    lazy var userAccount = WBUserAccount()
    
    /// 用户登录标记[计算型属性]
    var userLogon: Bool {
        return userAccount.access_token != nil
    }
    
    /// 专门负责拼接 token 的网络请求方法
    ///
    /// - parameter method:     GET / POST
    /// - parameter URLString:  URLString
    /// - parameter parameters: 参数字典
    /// - parameter name:       上传文件使用的字段名，默认为 nil，不上传文件
    /// - parameter data:       上传文件的二进制数据，默认为 nil，不上传文件
    /// - parameter completion: 完成回调
    func tokenRequest(method: WBHTTPMethod = .GET, URLString: String, parameters: [String: AnyObject]?, name: String? = nil, data: Data? = nil, completion: @escaping (_ json: Any?, _ isSuccess: Bool)->()) {
        
        // 处理 token 字典
        // 0> 判断 token 是否为 nil，为 nil 直接返回，程序执行过程中，一般 token 不会为 nil
        guard let token = userAccount.access_token else {
            
            // 发送通知，提示用户登录
            print("没有 token! 需要登录")
            
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: WBUserShouldLoginNotification),
                object: nil)
            
            completion(nil, false)
            
            return
        }
        
        // 1> 判断 参数字典是否存在，如果为 nil，应该新建一个字典
        var parameters = parameters
        if parameters == nil {
            // 实例化字典
            parameters = [String: AnyObject]()
        }
        
        // 2> 设置参数字典，代码在此处字典一定有值
        parameters!["access_token"] = token as AnyObject?
        
        // 3> 判断 name 和 data 
        if let name = name, let data = data {
            // 上传文件
            upload(URLString: URLString, parameters: parameters, name: name, data: data, completion: completion)
        } else {
            
            // 调用 request 发起真正的网络请求方法
            // request(URLString: URLString, parameters: parameters, completion: completion)
            request(method: method, URLString: URLString, parameters: parameters, completion: completion)
        }
    }
    
    // MARK: - 封装 AFN 方法
    /// 上传文件必须是 POST 方法，GET 只能获取数据
    /// 封装 AFN 的上传文件方法
    ///
    /// - parameter URLString:  URLString
    /// - parameter parameters: 参数字典
    /// - parameter name:       接收上传数据的服务器字段(name - 要咨询公司的后台) `pic`
    /// - parameter data:       要上传的二进制数据
    /// - parameter completion: 完成回调
    func upload(URLString: String, parameters: [String: AnyObject]?, name: String, data: Data, completion: @escaping (_ json: AnyObject?, _ isSuccess: Bool)->()) {
        
        post(URLString, parameters: parameters, constructingBodyWith: { (formData) in
            
            // 创建 formData
            /**
                1. data: 要上传的二进制数据
                2. name: 服务器接收数据的字段名
                3. fileName: 保存在服务器的文件名，大多数服务器，现在可以乱写
                    很多服务器，上传图片完成后，会生成缩略图，中图，大图...
                4. mimeType: 告诉服务器上传文件的类型，如果不想告诉，可以使用 application/octet-stream
                    image/png image/jpg image/gif
            */
            formData.appendPart(withFileData: data, name: name, fileName: "xxx", mimeType: "application/octet-stream")
            
            }, progress: nil, success: { (json, _) in
                
                completion(json, true)
            }) { (task, error) in
                
                if (task?.response as? HTTPURLResponse)?.statusCode == 403 {
                    print("Token 过期了")
                    
                    // 发送通知，提示用户再次登录(本方法不知道被谁调用，谁接收到通知，谁处理！)
                    NotificationCenter.default.post(
                        name: NSNotification.Name(rawValue: WBUserShouldLoginNotification),
                        object: "bad token")
                }
                
                print("网络请求错误 \(error)")
                
                completion(nil, false)
        }
    }
    
    /// 封装 AFN 的 GET / POST 请求
    ///
    /// - parameter method:     GET / POST
    /// - parameter URLString:  URLString
    /// - parameter parameters: 参数字典
    /// - parameter completion: 完成回调[json(字典／数组), 是否成功]
    func request(method: WBHTTPMethod = .GET, URLString: String, parameters: [String: AnyObject]?, completion: @escaping (_ json: Any?, _ isSuccess: Bool)->()) {
        
        // 成功回调
        let success = { (task: URLSessionDataTask, json: Any?)->() in
            
            completion(json, true)
        }
        
        // 失败回调
        let failure = { (task: URLSessionDataTask?, error: Error)->() in
            
            // 针对 403 处理用户 token 过期
            // 对于测试用户(应用程序还没有提交给新浪微博审核)每天的刷新量是有限的！
            // 超出上限，token 会被锁定一段时间
            // 解决办法，新建一个应用程序！
            if (task?.response as? HTTPURLResponse)?.statusCode == 403 {
                print("Token 过期了")
                
                // 发送通知，提示用户再次登录(本方法不知道被谁调用，谁接收到通知，谁处理！)
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: WBUserShouldLoginNotification),
                    object: "bad token")
            }
            
            // error 通常比较吓人，例如编号：XXXX，错误原因一堆英文！
            print("网络请求错误 \(error)")
            
            completion(nil, false)
        }
        
        if method == .GET {
            get(URLString, parameters: parameters, progress: nil, success: success, failure: failure)
        } else {
            
            post(URLString, parameters: parameters, progress: nil, success: success, failure: failure)
        }
    }
}
