//
//  ViewController.swift
//  DBFM
//
//  Created by andyyz on 15/12/7.
//  Copyright © 2015年 andyyz. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class ViewController: UIViewController ,UITableViewDelegate,UITableViewDataSource,HttpProtocol,ChannelProtocol{

    @IBOutlet weak var songTv: UITableView!
    @IBOutlet weak var bg: UIImageView!
    @IBOutlet weak var iv: CoverImage!
    
    
    var eHttp:HTTPController = HTTPController()
    
    //定义接收频道的歌曲数据
    var tableData:[JSON] = []
    //定义接收频道的数据
    var channelData:[JSON] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        songTv.delegate = self
        songTv.dataSource = self
        
        iv.onRotation()
        //设置背景模糊
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame.size = CGSize(width: view.frame.width, height: view.frame.height)
        bg.addSubview(blurView)
        
        eHttp.delegate = self
        //获取频道数据
        eHttp.onSearch("http://www.douban.com/j/app/radio/channels")
        //获取频道为0歌曲数据
        eHttp.onSearch("http://douban.fm/j/mine/playlist?type=n&channel=0&from=mainsite")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = songTv.dequeueReusableCellWithIdentifier("douban") as UITableViewCell!
  
        //获取cell的数据
        let rowData:JSON = tableData[indexPath.row]

        //设置cell的标题
        cell.textLabel?.text = rowData["title"].string
        cell.detailTextLabel?.text = rowData["artist"].string
        //设置缩略图
        cell.imageView!.image = UIImage(named: "thumb")
        //封面的网址
        let url = rowData["picture"].string
        
        Alamofire.request(.GET, url!).responseData {  response in
            let img = UIImage(data: response.result.value! as! NSData)
            cell.imageView?.image = img
        }
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //获取跳转目标
        let channelController:ChannelController = segue.destinationViewController as! ChannelController
        //设置代理
        channelController.delegate = self
        //传输频道列表数据
        channelController.channelData = self.channelData
    }

    
    func didRecieveResultsFromDouban(results:AnyObject) {
        let json = JSON(results)
        //判断是否是频道数据
        if let channels = json["channels"].array {
            self.channelData = channels
        }else if let song = json["song"].array {
            self.tableData = song
            //刷新歌曲列表数据
            self.songTv.reloadData()
        }
    }
    
    
    func onChangeChannel(channel_id:String) {
        //拼凑频道列表的歌曲数据网络地址
        let url:String = "http://douban.fm/j/mine/playlist?type=n&channel=\(channel_id)&from=mainsite"
        eHttp.onSearch(url)
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

