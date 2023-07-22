//
//  ViewController.swift
//  NetflixPlayer
//
//  Created by Pushpendra on 29/06/23.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var videoPlayer: UIView!
    @IBOutlet weak var videoPlayerHeight: NSLayoutConstraint!
    @IBOutlet weak var viewControll: UIView!
    @IBOutlet weak var stackCtrView: UIStackView!
    @IBOutlet weak var img10SecBack: UIImageView! {
        didSet {
            self.img10SecBack.isUserInteractionEnabled = true
            self.img10SecBack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap10SecBack)))
        }
    }
    @IBOutlet weak var imgPlay: UIImageView! {
        didSet {
            self.imgPlay.isUserInteractionEnabled = true
            self.imgPlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapPlayPause)))
        }
    }
    @IBOutlet weak var img10SecFor: UIImageView! {
        didSet {
            self.img10SecFor.isUserInteractionEnabled = true
            self.img10SecFor.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap10SecNext)))
        }
    }
    
    @IBOutlet weak var lbCurrentTime: UILabel!
    @IBOutlet weak var lbTotalTime: UILabel!
    @IBOutlet weak var seekSlider: UISlider! {
        didSet {
            self.seekSlider.addTarget(self, action: #selector(onTapToSlide), for: .valueChanged)
        }
    }
    @IBOutlet weak var imgFullScreenToggle: UIImageView! {
        didSet {
            self.imgFullScreenToggle.isUserInteractionEnabled = true
            self.imgFullScreenToggle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapToggleScreen)))
        }
    }
    @IBOutlet weak var imgThumnail: UIImageView!
    
    
    let videoURL = "https://action-ott-live.s3.ap-south-1.amazonaws.com/Raees/Raees.mp4"
    let spritURL = "https://action-ott-live.s3.amazonaws.com/uploads/seekbar_thumbnails/movie_209.jpg"
    override func viewDidLoad() {
        super.viewDidLoad()
        self.downlodThumnailImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setVideoPlayer()
        self.scribingAndPositioning(show: false)
    }

    private var player : AVPlayer? = nil
    private var playerLayer : AVPlayerLayer? = nil
    
    private func setVideoPlayer() {
        guard let url = URL(string: videoURL) else { return }
        
        if self.player == nil {
            self.player = AVPlayer(url: url)
            self.playerLayer = AVPlayerLayer(player: self.player)
            self.playerLayer?.videoGravity = .resizeAspectFill
            self.playerLayer?.frame = self.videoPlayer.bounds
            self.playerLayer?.addSublayer(self.viewControll.layer)
            if let playerLayer = self.playerLayer {
                self.view.layer.addSublayer(playerLayer)
            }
            self.player?.play()
        }
        self.setObserverToPlayer()
    }
    
    private var windowInterface : UIInterfaceOrientation? {
        return self.view.window?.windowScene?.interfaceOrientation
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard let windowInterface = self.windowInterface else { return }
        if windowInterface.isPortrait ==  true {
            self.videoPlayerHeight.constant = 300
        } else {
            self.videoPlayerHeight.constant = self.view.layer.bounds.width
        }
        print(self.videoPlayerHeight.constant)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.playerLayer?.frame = self.videoPlayer.bounds
        })
    }
    
    private var thumanilImage : UIImage? = nil
    private func downlodThumnailImage() {
        if self.thumanilImage == nil {
            if let url = URL(string: self.spritURL) {
                let urlRequest = URLRequest(url: url)
                URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                    DispatchQueue.main.async {
                        if let data = data {
                            print("Image is Downloaded")
                            self.thumanilImage = UIImage(data: data)
                            self.imgThumnail.image = self.thumanilImage
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func scribingAndPositioning(show : Bool) {
        let trackRec = self.seekSlider.trackRect(forBounds: self.seekSlider.bounds)
        let thumbRect = self.seekSlider.thumbRect(forBounds: self.seekSlider.bounds, trackRect: trackRec, value: self.seekSlider.value)
        if show == true {
            self.imgThumnail.isHidden = false
            
            let x = thumbRect.origin.x + self.seekSlider.frame.origin.x
            let y = self.seekSlider.frame.origin.y - 45
            self.imgThumnail.center = CGPoint(x: x, y: y)
        } else {
            self.imgThumnail.isHidden = true
        }
    }
    
    private func setImage(position : Double)  {
        if let thumanilImage = thumanilImage {
            let interval = 10 * 1000
           // let row = 29
            let coulmn = 30
            let height = 63
            let width = 150
            
            var x = 0
            var y = 0
            
            let square = Int(position) / interval
            y = square / coulmn
            x = square % coulmn
            
            UIGraphicsBeginImageContext(CGSize(width: width, height: height))
            let xCrop = CGFloat(x) * CGFloat(width) * thumanilImage.scale
            let yCrop = CGFloat(y) * CGFloat(height) * thumanilImage.scale
            
            let wCrop = CGFloat(width) * thumanilImage.scale
            let hCrop = CGFloat(height) * thumanilImage.scale
            
            if let croppedImage = self.thumanilImage?.cgImage?.cropping(to: CGRect.init(x: xCrop, y: yCrop, width: wCrop, height: hCrop)) {
                let newImage  = UIImage.init(cgImage: croppedImage)
                self.imgThumnail.image = newImage
            }
            UIGraphicsEndImageContext()
        }
    }
    
    
    private var timeObserver : Any? = nil
    private func setObserverToPlayer() {
        let interval = CMTime(seconds: 0.3, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsed in
            self.updatePlayerTime()
        })
    }
    
    private func updatePlayerTime() {
        guard let currentTime = self.player?.currentTime() else { return }
        guard let duration = self.player?.currentItem?.duration else { return }
        
        let currentTimeInSecond = CMTimeGetSeconds(currentTime)
        let durationTimeInSecond = CMTimeGetSeconds(duration)
        
        if self.isThumbSeek == false {
            self.seekSlider.value = Float(currentTimeInSecond/durationTimeInSecond)
        }
        
        let value = Float64(self.seekSlider.value) * CMTimeGetSeconds(duration)
        
        var hours = value / 3600
        var mins =  (value / 60).truncatingRemainder(dividingBy: 60)
        var secs = value.truncatingRemainder(dividingBy: 60)
        var timeformatter = NumberFormatter()
        timeformatter.minimumIntegerDigits = 2
        timeformatter.minimumFractionDigits = 0
        timeformatter.roundingMode = .down
        guard let hoursStr = timeformatter.string(from: NSNumber(value: hours)), let minsStr = timeformatter.string(from: NSNumber(value: mins)), let secsStr = timeformatter.string(from: NSNumber(value: secs)) else {
            return
        }
        self.lbCurrentTime.text = "\(hoursStr):\(minsStr):\(secsStr)"
        
        hours = durationTimeInSecond / 3600
        mins = (durationTimeInSecond / 60).truncatingRemainder(dividingBy: 60)
        secs = durationTimeInSecond.truncatingRemainder(dividingBy: 60)
        timeformatter = NumberFormatter()
        timeformatter.minimumIntegerDigits = 2
        timeformatter.minimumFractionDigits = 0
        timeformatter.roundingMode = .down
        guard let hoursStr = timeformatter.string(from: NSNumber(value: hours)), let minsStr = timeformatter.string(from: NSNumber(value: mins)), let secsStr = timeformatter.string(from: NSNumber(value: secs)) else {
            return
        }
        self.lbTotalTime.text = "\(hoursStr):\(minsStr):\(secsStr)"
    }
    
    
    @objc private func onTap10SecNext() {
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10Sec = CMTimeGetSeconds(currentTime).advanced(by: 10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10Sec), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
            
        })
    }
    
    @objc private func onTap10SecBack() {
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10Sec = CMTimeGetSeconds(currentTime).advanced(by: -10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10Sec), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
            
        })
    }
    
    @objc private func onTapPlayPause() {
        if self.player?.timeControlStatus == .playing {
            self.imgPlay.image = UIImage(systemName: "pause.circle")
            self.player?.pause()
        } else {
            self.imgPlay.image = UIImage(systemName: "play.circle")
            self.player?.play()
        }
    }
    
    private var isThumbSeek : Bool = false
    @objc private func onTapToSlide() {
        self.isThumbSeek = true
        if self.seekSlider.isTracking == true {
            
            self.setThumnailToImage()
            self.scribingAndPositioning(show: true)
        } else {
            guard let duration = self.player?.currentItem?.duration else { return }
            let value = Float64(self.seekSlider.value) * CMTimeGetSeconds(duration)
            if value.isNaN == false {
                let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
                self.player?.seek(to: seekTime, completionHandler: { completed in
                    if completed {
                        self.isThumbSeek = false
                        self.scribingAndPositioning(show: false)
                    }
                })
            }
        }
    }
    
    private func setThumnailToImage() {
        DispatchQueue.main.async {
            if let duration = self.player?.currentItem?.duration {
                let value = Float64(self.seekSlider.value) * CMTimeGetSeconds(duration)
                self.setImage(position: value * 1000)
            }
        }
    }
    
    @objc private func onTapToggleScreen() {
        if #available(iOS 16.0, *) {
            guard let windowSceen = self.view.window?.windowScene else { return }
            if windowSceen.interfaceOrientation == .portrait {
                windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                    print(error.localizedDescription)
                }
            } else {
                windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
                    print(error.localizedDescription)
                }
            }
        } else {
            if UIDevice.current.orientation == .portrait {
                let orientation = UIInterfaceOrientation.landscapeRight.rawValue
                UIDevice.current.setValue(orientation, forKey: "orientation")
            } else {
                let orientation = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(orientation, forKey: "orientation")
            }
        }
    }
}

