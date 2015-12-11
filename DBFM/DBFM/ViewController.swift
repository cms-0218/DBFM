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
    @IBOutlet weak var btnOrder: OrderButton!
    @IBOutlet weak var btnPlay: dbButton!
    @IBOutlet weak var btnPre: dbButton!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var songProgress: UIImageView!
    
    //网络数据实例
    var eHttp:HTTPController = HTTPController()
    //媒体播放器
    var audioPlayer:MPMoviePlayerController =  MPMoviePlayerController()
    //图片缓存数据结构
    var imageCache = Dictionary<String,UIImage>()
    //定义接收频道的歌曲数据
    var songData:[JSON] = []
    //定义接收频道的数据
    var channelData:[JSON] = []
    //计时器
    var timer:NSTimer?
    //当前在播放第几首
    var currIndex:Int = 0

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
        eHttp.onSearch("http://douban.fm/j/mine/playlist?type=n&channel=10&from=mainsite")
        
        
        //监听按钮点击
        btnPlay.addTarget(self, action: "onPlay:", forControlEvents: UIControlEvents.TouchUpInside)
        btnNext.addTarget(self, action: "onClick:", forControlEvents: UIControlEvents.TouchUpInside)
        btnPre.addTarget(self, action: "onClick:", forControlEvents: UIControlEvents.TouchUpInside)
        btnOrder.addTarget(self, action: "onOrder:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //播放结束通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playFinish", name: MPMoviePlayerPlaybackDidFinishNotification, object: audioPlayer)
    }
    
    var isAutoFinish:Bool = true
    func playFinish(){
        if isAutoFinish {
            switch(btnOrder.order){
            case 1:
                //顺序播放
                currIndex++
                if currIndex > songData.count - 1 {
                    self.currIndex = 0
                }
                onSelectRow(currIndex)
            case 2:
                //随机播放
                currIndex = random() % songData.count
                onSelectRow(currIndex)
            case 3:
                //单曲循环
                onSelectRow(currIndex)
            default:
                "default"
            }
        }else{
            isAutoFinish = true
        }
        
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
            let img = UIImage(data: response.result.value! )
            cell.imageView?.image = img
        }
        return cell
    }
    
    //设置cell的显示动画
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //设置cell的显示动画为3d缩放，xy方向的缩放动画，初始值为0.1 结束值为1
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        })
    }
    
    //点击歌曲
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        isAutoFinish = false
        onSelectRow(indexPath.row)
    }
    //跳转至频道列表
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let channelController:ChannelController = segue.destinationViewController as! ChannelController
        channelController.delegate = self
        channelController.channelData = self.channelData
    }

    //获取数据并解析
    func didRecieveResultsFromDouban(results:AnyObject) {
        let json = JSON(results)
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
        let indexPath:NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
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
                let img = UIImage(data: response.result.value! )
                imgView.image = img
                self.imageCache[url] = img
            }

        }else{
            //如果缓存中有，就直接用
            imgView.image = image!
        }
    }

  
    func onOrder(btn:OrderButton){
        var message:String = ""
        switch(btn.order){
        case 1:
            message = "顺序播放"
        case 2:
            message = "随机播放"
        case 3:
            message = "单曲循环"
        default:
            message = ""
        }
        self.view.makeToast(message: message, duration: 0.5, position: "center")
    }
    func onClick(btn:UIButton){
        isAutoFinish = false
        if btn == btnNext {
            currIndex++
            if currIndex > self.songData.count - 1 {
                currIndex = 0
            }
        }else{
            currIndex--
            if currIndex < 0 {
                currIndex = self.songData.count - 1
            }
        }
        onSelectRow(currIndex)
    }
    func onPlay(btn:dbButton){
        if btn.isPlay{
            audioPlayer.play()
        }else{
            audioPlayer.pause()
        }
    }

    
    //播放音乐的方法
    func onSetAudio(url:String){
        self.audioPlayer.stop()
        self.audioPlayer.contentURL = NSURL(string: url)
        self.audioPlayer.play()
        
        btnPlay.onPlay()
        
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
            songProgress.frame.size.width = view.frame.size.width * pro
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

