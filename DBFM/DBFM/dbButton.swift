//
//  doubanBtn.swift
//  DBFM
//
//  Created by andyyz on 15/12/11.
//  Copyright © 2015年 andyyz. All rights reserved.
//

import UIKit

class dbButton: UIButton {
    var isPlay:Bool = true
    let imgPlay:UIImage = UIImage(named: "play")!
    let imgPause:UIImage = UIImage(named: "pause")!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addTarget(self, action: "onClick", forControlEvents: UIControlEvents.TouchUpInside)
    }
    func onClick(){
        isPlay = !isPlay
        if isPlay{
            self.setImage(imgPause, forState: UIControlState.Normal)
        }else{
            self.setImage(imgPlay, forState: UIControlState.Normal)
        }
    }
    func onPlay(){
        isPlay = true
        self.setImage(imgPause, forState: UIControlState.Normal)
    }
}

