//
//  ChannelController.swift
//  DBFM
//
//  Created by andyyz on 15/12/10.
//  Copyright © 2015年 andyyz. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

protocol ChannelProtocol{
    //回调，将频道id传回到代理中
    func onChangeChannel(channel_id:String)
}

class ChannelController: UIViewController,UITableViewDataSource,UITableViewDelegate{
    
    @IBOutlet weak var channelTable: UITableView!
    
    var delegate:ChannelProtocol?
    
    //频道列表数据
    var channelData:[JSON] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0.8
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = channelTable.dequeueReusableCellWithIdentifier("channel") as UITableViewCell!
        
        let rowData:JSON = self.channelData[indexPath.row] as JSON
        cell.textLabel?.text = rowData["name"].string

        return cell;
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let rowData:JSON = self.channelData[indexPath.row] as JSON
        //获取选中行的频道id
        let channel_id:String = rowData["channel_id"].stringValue
        //将频道id反向传给主界面
        delegate?.onChangeChannel(channel_id)
        //关闭当前界面
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    //设置cell的显示动画
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //设置cell的显示动画为3d缩放，xy方向的缩放动画，初始值为0.1 结束值为1
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        })
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
}
