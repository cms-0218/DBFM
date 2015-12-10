//
//  ViewController.swift
//  DBFM
//
//  Created by andyyz on 15/12/7.
//  Copyright © 2015年 andyyz. All rights reserved.
//

import UIKit
import MediaPlayer
import SwiftyJSON
import Alamofire

class ViewController: UIViewController ,UITableViewDelegate,UITableViewDataSource,HttpProtocol,ChannelProtocol{

    @IBOutlet weak var songTv: UITableView!
    @IBOutlet weak var bg: UIImageView!
    @IBOutlet weak var iv: CoverImage!
    
    @IBOutlet weak var playTimeLabel: UILabel!
  
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnPre: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
    var eHttp:HTTPController = HTTPController()
    
    //媒体播放器
    var audioPlayer:MPMoviePlayerController =  MPMoviePlayerController()
    
    var imageCache = Dictionary<String,UIImage>()

    
    //定义接收频道的歌曲数据
    var songData:[JSON] = []
    //定义接收频道的数据
    var channelData:[JSON] = []
    
    var timer:NSTimer?
    
    var isAutoFinish:Bool = true

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
        return songData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = songTv.dequeueReusableCellWithIdentifier("douban") as UITableViewCell!
  
        //获取cell的数据
        let rowData:JSON = songData[indexPath.row]

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
    
    //点击了哪一首歌曲
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        isAutoFinish = false
        onSelectRow(indexPath.row)
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
        print("获取到得数据：\(results)")
        let json = JSON(results)
        print(json["song"].array?.count)
        //判断是否是频道数据
        if let channels = json["channels"].array {
            self.channelData = channels
        }else if let song = json["song"].array {
            self.songData = song
            //刷新歌曲列表数据
            self.songTv.reloadData()
            onSelectRow(0)
        }
    }
    
    
    func onChangeChannel(channel_id:String) {
        //拼凑频道列表的歌曲数据网络地址
        let url:String = "http://douban.fm/j/mine/playlist?type=n&channel=\(channel_id)&from=mainsite"
        eHttp.onSearch(url)
    }

    //选中哪一首歌曲
    func onSelectRow(index:Int){
        //构建一个indexPath
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        //选中的效果
        songTv.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.Top)
        //获取行数据
        var rowData:JSON = self.songData[index] as JSON
        //获取该行图片的地址
        let imgUrl = rowData["picture"].string
        //设置封面以及背景
        onSetImage(imgUrl!)
        //获取音乐的文件地址
        let url:String = rowData["url"].string!
        //播放音乐
        onSetAudio(url)
    }
    //设置歌曲的封面以及背景
    func onSetImage(url:String){
        onGetCacheImage(url, imgView: self.iv)
        onGetCacheImage(url, imgView: self.bg)
    }
    
    //图片缓存策略方法
    func onGetCacheImage(url:String,imgView:UIImageView){
        //通过图片地址去缓存中取图片
        let image = self.imageCache[url] as UIImage?
        
        if image == nil {
            //如果缓存中没有这张图片，就通过网络获取
    
            Alamofire.request(.GET, url).responseData {  response in
                let img = UIImage(data: response.result.value! as! NSData)
                imgView.image = img
                self.imageCache[url] = img
            }

        }else{
            //如果缓存中有，就直接用
            imgView.image = image!
        }
    }

    
    //播放音乐的方法
    func onSetAudio(url:String){
        self.audioPlayer.stop()
        self.audioPlayer.contentURL = NSURL(string: url)
        self.audioPlayer.play()
        
       // btnPlay.onPlay()
        
        //先停掉计时器
        timer?.invalidate()
        //将计时器归零
        playTimeLabel.text = "00:00"
        
        //启动计时器
        timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "onUpdate", userInfo: nil, repeats: true)
        
        isAutoFinish = true
    }
    //计时器更新方法
    func onUpdate(){
        // 00:00 获取播放器当前的播放时间
        let c = audioPlayer.currentPlaybackTime
        if c>0.0 {
            
            //歌曲的总时间
            let t = audioPlayer.duration
            
            //计算百分比
            let pro:CGFloat = CGFloat(c/t)
            //按百分比显示进度条的宽度
           // progress.frame.size.width = view.frame.size.width * pro
            //这是一个小算法，来实现 00:00 这种样式的播放时间
            
            let all:Int = Int(c)
            let m:Int = all % 60
            let f:Int = Int(all/60)
            
            var time:String = ""
            if f<10 {
                time = "0\(f):"
            }else{
                time = "\(f):"
            }
            
            if m<10 {
                time+="0\(m)"
            }else{
                time+="\(m)"
            }
            //更新播放时间
            playTimeLabel.text = time
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

