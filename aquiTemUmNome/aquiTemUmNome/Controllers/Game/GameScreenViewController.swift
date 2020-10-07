//
//  GameScreenViewController.swift
//  aquiTemUmNome
//
//  Created by Cecilia Soares on 17/09/20.
//  Copyright © 2020 aquiTemUmNomeOrganization. All rights reserved.
//

import UIKit

// swiftlint:disable line_length

class GameScreenViewController: UIViewController {

    let musicManager = MusicManager.shared

    lazy var mainView: GameScreenView = {
        let gameView = GameScreenView(frame: self.view.frame)

        let singleTapLeft: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapLeft))
        singleTapLeft.numberOfTapsRequired = 1
        singleTapLeft.numberOfTouchesRequired = 1
        gameView.leftView.addGestureRecognizer(singleTapLeft)
        gameView.leftView.isUserInteractionEnabled = true

        let singleTapRight: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapRight))
        singleTapRight.numberOfTapsRequired = 1
        singleTapRight.numberOfTouchesRequired = 1
        gameView.rightView.addGestureRecognizer(singleTapRight)
        gameView.rightView.isUserInteractionEnabled = true

        gameView.pause.addTarget(self, action: #selector(pauseGame), for: .touchUpInside)

        gameView.delegate = self
        return gameView
    }()

    let queueMove = DispatchQueue(label: "MoveQueue")

    var boardManager: BoardManager?
    lazy var animator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self.view)
    var timer: Timer = Timer()
    var isTimerRunning = false

    var score: Int = 0 {
        didSet {
            self.mainView.score.setScore(score: self.score)
            switch score {
            case 0...50:
                self.boardManager?.setDificultt(difficulty: .easiest)
                if score == 0 {
                    musicManager.playIntro()
                }
            case 51...100:
                self.boardManager?.setDificultt(difficulty: .easy)
                if score == 52 {
                    musicManager.playEasyMusic()
                }
            case 101...200:
                self.boardManager?.setDificultt(difficulty: .normal)
                if score == 102 {
                    musicManager.playMediumMusic()
                }
            case 201...350:
                self.boardManager?.setDificultt(difficulty: .hard)
                if score == 202 {
                    musicManager.playMediumMusic()
                }
            default:
                self.boardManager?.setDificultt(difficulty: .hardest)
                if score == 352 {
                    musicManager.playMediumMusic()
                }
            }

            self.timeFrame = self.boardManager?.getDificultt().timeFrame ?? 1
        }
    }

    var timeFrame: TimeInterval = 1 {
        didSet {
            self.timer.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: self.timeFrame, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = mainView
    }

    @objc func pauseGame() {
        self.pauseTimer()

        self.mainView.removeBehaviorsObstacle(animator: self.animator)
        musicManager.stopMusic()

        let pauseViewController = PauseViewController()
        pauseViewController.delegate = self

        let pauseController = UINavigationController(rootViewController: pauseViewController)
        pauseController.modalPresentationStyle = .overFullScreen
        pauseController.isNavigationBarHidden = true
        present(pauseController, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.boardManager = BoardManager(screenWidth: self.view.bounds.size.width)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playTimer()
        isTimerRunning = true
    }

    private func createObstacle() {
        let obstacle = self.boardManager?.getObstacle()
        let width = self.boardManager?.getObstacleWidth()
        let gravity = self.boardManager?.getDificultt().gravity

        self.mainView.createNewObstacle(with: obstacle!.1, set: obstacle!.0, size: width!, animator: self.animator, acceleration: CGFloat(gravity ?? 0.3))
    }

    private func playTimer() {
        if !self.isTimerRunning {
            self.timer = Timer.scheduledTimer(timeInterval: self.timeFrame, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        }
    }

    func cancelTimer() {
        timer.invalidate()
        isTimerRunning = false
    }

    func pauseTimer() {
        timer.invalidate()
        isTimerRunning = false
    }

    @objc func updateTimer() {
        self.createObstacle()
        self.score += 2
    }

    @objc func tapLeft(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.ended {
            let position = self.boardManager?.moveCharacter(movement: .left, xCurrent: self.mainView.character.frame.origin.x)
            self.mainView.moveCharacter(with: Int(position!), animator: self.animator)
        }
    }

    @objc func tapRight(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.ended {
            let position = self.boardManager?.moveCharacter(movement: .right, xCurrent: self.mainView.character.frame.origin.x)
            self.mainView.moveCharacter(with: Int(position!), animator: self.animator)
        }
    }
}

extension GameScreenViewController: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item1: UIDynamicItem, with item2: UIDynamicItem) {
        self.cancelTimer()

        let gameOverController = GameOverViewController()
        gameOverController.setupScore(with: self.score)

        let gameNavigationController = UINavigationController(rootViewController: gameOverController)
        gameNavigationController.modalPresentationStyle = .overFullScreen
        gameNavigationController.isNavigationBarHidden = true
        present(gameNavigationController, animated: true, completion: nil)

    }
}

extension GameScreenViewController: PauseDelegate {
    func returnGame() {
        self.mainView.addBehaviorsObstacle(animator: self.animator)
        self.playTimer()
        isTimerRunning = true

        let dificult = self.boardManager?.getDificultt()
        switch dificult! {
        case .easy:
            self.musicManager.playIntro()
        case .normal:
            self.musicManager.playEasyMusic()
        case .hard:
            self.musicManager.playMediumMusic()
        case .easiest:
            self.musicManager.playIntro()
        case .hardest:
            self.musicManager.playMediumMusic()
        }
    }
}
