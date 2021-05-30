//
//  GameScene.swift
//  FlappyBird
//
//  Created by 白土顕一 on 2021/05/22.
//

import SpriteKit
import AVFoundation


class GameScene: SKScene, SKPhysicsContactDelegate {

    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKNode!
    var itemNode:SKNode!
    
    var audioPlayer: AVAudioPlayer?
    var audioPlayerInstance : AVAudioPlayer! = nil  // 再生するサウンドのインスタンス

    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemCategory: UInt32 = 1 << 4       // 0...10000
    
    
    // スコア用
    var score = 0
    var scoreItem = 0
    var scoreLabelNode:SKLabelNode!         // 現在のスコア表示
    var bestScoreLabelNode:SKLabelNode!     // ベストスコア表示
    var itemScoreLabelNode:SKLabelNode!     // アイテムスコア表示
    
    
    // ベストスコアをUserDefaultsで保存する為の取得
    let userDefaults:UserDefaults = UserDefaults.standard
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        
        // アイテムのノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupItem()
        
        
        // Do any additional setup after loading the view, typically from a nib.
                // サウンドファイルのパスを生成(今回のファイルに導入した画像ファイル名を書きます)
                let soundFilePath = Bundle.main.path(forResource: "item sound", ofType: "mp3")!
                let sound:URL = URL(fileURLWithPath: soundFilePath)
                // AVAudioPlayerのインスタンスを作成,ファイルの読み込み
                do {
                    audioPlayerInstance = try AVAudioPlayer(contentsOf: sound, fileTypeHint:nil)
                } catch {
                    print("AVAudioPlayerインスタンス作成でエラー")
                }
                // 再生準備
                audioPlayerInstance.prepareToPlay()
                // Do any additional setup after loading the view, typically from a nib.
            
        
        
    }
        
   
    
    // アイテム
    func setupItem() {
        
        // アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = .linear //.linear : 画像はきれいだが処理が遅い
        
        // 移動する距離を計算
        let itemMovingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分をn秒でスクロールさせるアクション
        let moveItem = SKAction.moveBy(x: -itemMovingDistance, y: self.frame.size.height, duration: 5)

        // 自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()

        // 左方向にスクロールするアクションと元の位置に戻すアクションを無限に繰り返すアクション
        let itemAnimation = SKAction.repeatForever(SKAction.sequence([moveItem, removeItem]))

        
        // アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run({
        
            //let item = SKNode()
            //item.addChild(SKSpriteNode(texture: itemTexture))
            let item = SKSpriteNode(texture: itemTexture)
            item.position = CGPoint(
                x: self.frame.size.width + itemTexture.size().width / 2 ,
                y: 0
            )
            
            // 物理演算を設定
            item.physicsBody = SKPhysicsBody(circleOfRadius: item.frame.size.height / 2)
            item.physicsBody?.categoryBitMask = self.itemCategory
            
            // 衝突の時に動かないように設定する
            item.physicsBody?.isDynamic = false
            
            item.physicsBody?.categoryBitMask = self.itemCategory
            item.physicsBody?.contactTestBitMask = self.birdCategory
            
            
            // 前面に表示
            item.zPosition = 100
            
            // スプライトにアクションを設定する
            item.run(itemAnimation)
            
            // スプライトを追加する
            self.itemNode.addChild(item)
            
        })
            
        // 次のアイテム作成までの時間待ちのアクションを作成
        let waitItemAnimation = SKAction.wait(forDuration: 15)
        
        // アイテムを作成->時間待ち->アイテムを作成を無限に繰り返すアクションを作成
        let repeatItemForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation,waitItemAnimation]))
        
            // スプライトにアクションを設定する
        itemNode.run(repeatItemForeverAnimation)

    }
    
    
    
    
    
    
    
    // 地面
    func setupGround() {
    
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest  //.nearest : 画像が荒くなるが処理が速い
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分を５秒でスクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)

        // 元の位置に０秒で戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        // 左方向にスクロールするアクションと元の位置に戻すアクションを無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
            
        }
    }
        // テクスチャを指定してスプライトを作成する
        // テクスチャとはSpriteKitではSKTextureで扱う画像のこと
        //let groundSprite = SKSpriteNode(texture: groundTexture)

        // スプライトの表示する位置を指定する
        //groundSprite.position = CGPoint(
        //    x: groundTexture.size().width / 2,
        //    y: groundTexture.size().height / 2
        //)

        // シーンにスプライトを追加する
        //addChild(groundSprite)
       
    
    
    // 雲
    func setupCloud() {
        
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest   //.nearest : 画像が荒くなるが処理が速い
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分を２０秒でスクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)

        // 元の位置に０秒で戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)

        // 左方向にスクロールするアクションと元の位置に戻すアクションを無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

        // cloudのスプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)

        }
    }
    
    
    // 壁
    func setupWall() {
        
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear //.linear : 画像はきれいだが処理が遅い
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)

        // 画面外まで４秒で移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // ２つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall,removeWall])

        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の長さを鳥のサイズの３倍とする
        let slit_length = birdSize.height * 3
        
        // 隙間位置の上下の振れ幅を鳥のサイズの2.5倍とする

        let random_y_range = birdSize.height * 2.5
        
        // 下の壁のY軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置）を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // 0~random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)

            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0,y: under_wall_y)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            

            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
            
        })
        
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
        
    }
    
    
    // 鳥
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA,birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)

        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.frame.size.height / 2)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        
        // 衝突した時に跳ね返る動作をする相手
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        
        // 衝突することを判定する相手
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
        
    }
    
    
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scrollNode.speed > 0 {
        
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
        
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        
            
        // リスタートの条件
        } else if bird.speed == 0 {
            restart()
        }
            
    }
    
    
    
    // SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory
        
        {
            
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"  // 画面のスコアの更新
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)" // 画面のベストスコアの更新
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize() // 即座に保存
            }
        }
            
        
            // アイテムに衝突した時
            else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory ||
                    (contact.bodyB.categoryBitMask & itemCategory) == itemCategory
            {
                
                // アイテムスコア +1
                scoreItem += 1
                itemScoreLabelNode.text = "Item Score:\(scoreItem)"  // 画面のスコアの更新
                print("item score")
                
                // 効果音の再生
                audioPlayerInstance.currentTime = 0         // 再生箇所を頭に移す
                audioPlayerInstance.play()                  // 再生する
                
                // アイテムを消す
                itemNode.removeAllChildren()
            }
        
            
            
            // スコア用の物体、アイテム以外と衝突した時
        else {
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        
        }
 
    }
    
    
    // リスタート処理
    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"  // リスタート時の画面のスコアを0に更新
        
        scoreItem = 0
        itemScoreLabelNode.text = "Item Score:\(scoreItem)" // リスタート時の画面のアイテムスコアを0に更新
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
        
    }
    
    
    
    // スコア
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        
        scoreItem = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(scoreItem)"
        self.addChild(itemScoreLabelNode)
        
        
    }
    
    
    }
    
    

