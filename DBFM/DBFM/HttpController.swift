//
//  HttpController.swift
//  DBFM
//
//  Created by andyyz on 15/12/9.
//  Copyright © 2015年 andyyz. All rights reserved.
//

import Alamofire
import SwiftyJSON



class HTTPController:NSObject{
    //定义代理
    var delegate:HttpProtocol?

    //接收网址，回调代理的方法传回数据
    func onSearch(url:String){
        Alamofire.request(Method.GET, url).responseJSON { response in
                self.delegate?.didRecieveResultsFromDouban(response.result.value!)
            }
    }
}
//定义http协议
protocol HttpProtocol {
    func didRecieveResultsFromDouban(results:AnyObject)
}
