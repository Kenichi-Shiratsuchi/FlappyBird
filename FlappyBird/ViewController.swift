//
//  ViewController.swift
//  FlappyBird
//
//  Created by 白土顕一 on 2021/05/21.
//

import UIKit
import SpriteKit
import AVFoundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // SKViewに型を変換する
        let skView = self.view as! SKView
        
        // FPSを表示する
        skView.showsFPS = true
        
        // ノードの数を表示する
        skView.showsNodeCount = true
        
        // ビューと同じサイズでシーンを作成する
        let scene = GameScene(size:skView.frame.size)
        
        // ビューにシーンを表示する
        skView.presentScene(scene)
        
    }
    
    
    // ステータスバーの非表示
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }


}

