import UIKit
import CoreImage
import AVFoundation

extension Array {
    /// Picks `n` random elements (partial Fisher-Yates shuffle approach)
    subscript (randomPick n: Int) -> [Element] {
        var copy = self
        for i in stride(from: count - 1, to: count - n - 1, by: -1) {
            copy.swapAt(i, Int(arc4random_uniform(UInt32(i + 1))))
        }
        return Array(copy.suffix(n))
    }
}

extension UIViewController{
    
    func showToast(message : String, seconds: Double){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = .black
        alert.view.alpha = 0.5
        alert.view.layer.cornerRadius = 15
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
}

class MainVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameOverText: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var timerText: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var mainMenuView: UIView!
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var usernameEntry: UITextField!
    
    var player: AVAudioPlayer?
    var secondsRemaining = 10
    var timer: Timer?
    var cameraDevice: AVCaptureDevice?
    var quizLogic = Quiz()
    var isGameRunning = false
    var captureSession:AVCaptureSession?
    var previewLayer:AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        quizLogic.readJson()
        self.usernameEntry.delegate = self
    }
    
    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func playPressed(_ sender: Any) {
        quizLogic.resetQuiz()
        mainMenuView.isHidden = true
        gameView.isHidden = false
        gameOverView.isHidden = true
        startGame()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameView.isHidden = true
        gameOverView.isHidden = true
        mainMenuView.isHidden = false
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for metadataObject in metadataObjects as! [AVMetadataFaceObject] {
            DispatchQueue.main.async {
                if(self.isGameRunning==true){
                    if(metadataObject.hasYawAngle){
                        if(Int(metadataObject.yawAngle) == 315){
                            self.isGameRunning = false
                            self.checkAnswer(answer: true)
                        }else if (Int(metadataObject.yawAngle) == 45){
                            self.isGameRunning = false
                            self.checkAnswer(answer: false)
                        }
                    }
                }
            }
        }
    }
    
    func playSound(which: Int) {
        
        var url:URL? = nil
        
        if (which == 0){
            url = Bundle.main.url(forResource: "correct", withExtension: "mp3")
        }else if(which == 1){
            url = Bundle.main.url(forResource: "wrong", withExtension: "mp3")
        }else{
            url = Bundle.main.url(forResource: "timeout", withExtension: "mp3")
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url!, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func checkAnswer(answer: Bool){
        let userGotItRight = quizLogic.checkAnswer(userAnswer: answer)
        
        if userGotItRight{
            playSound(which: 0)
            questionLabel.backgroundColor = UIColor.green
        }else{
            playSound(which: 1)
            questionLabel.backgroundColor = UIColor.red
        }
        endTimer()
        
        
        perform(#selector(checkIfCanContinue), with: nil, afterDelay: 1)
    }
    
    func startGame(){
        isGameRunning = true
        quizLogic.quiz = quizLogic.allQuestions[randomPick: 10]
        updateUI()
        openCamera()
    }
    
    func endTimer(){
        if(timer != nil){
            timer?.invalidate()
            timer = nil
        }
    }
    
    func startTimer() {
        secondsRemaining = 10
        self.timerText.textColor = UIColor.red
        self.timerText.text = String(format: "%02d sec", self.secondsRemaining)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (Timer) in
            if self.secondsRemaining > 0 {
                self.timerText.text = String(format: "%02d sec", self.secondsRemaining)
                self.secondsRemaining -= 1
                if(self.timerText.textColor == UIColor.red){
                    self.timerText.textColor = UIColor.blue
                }else{
                    self.timerText.textColor = UIColor.red
                }
            } else {
                if let timer = self.timer {
                    timer.invalidate()
                    self.playSound(which: 2)
                    self.timerText.textColor = UIColor.systemPurple
                    self.questionLabel.backgroundColor = UIColor.orange
                    self.perform(#selector(self.checkIfCanContinue), with: nil, afterDelay: 1)
                    self.timer = nil
                }
            }
        }
    }
    
    @objc func checkIfCanContinue() {
        if(quizLogic.getProgress() + 0.1 == 1.0){
            perform(#selector(endGame), with: nil, afterDelay: 1)
            return
        }
        
        quizLogic.nextQuestion()
        updateUI()
        
        perform(#selector(continueGame), with: nil, afterDelay: 1)
    }
    
    @objc func endGame(){
        isGameRunning = false
        endTimer()
        questionLabel.backgroundColor = UIColor.clear
        videoView.layer.sublayers?.removeFirst()
        previewLayer = nil
        captureSession!.stopRunning()
        captureSession = nil
        mainMenuView.isHidden = true
        gameView.isHidden = true
        gameOverView.isHidden = false
        gameOverText.text = "GAME OVER\nScore : \(quizLogic.getScore())"
    }
    
    @IBAction func onViewTapped(_ sender: Any) {
        usernameEntry.resignFirstResponder()
    }
    
    @IBAction func saveToScoreboard(){
        var alert:UIAlertController!
        if(!self.usernameEntry.text!.isEmpty){
            if(self.usernameEntry.text!.count >= 2 && self.usernameEntry.text!.count <= 15){
                self.saveNewItem(username: self.usernameEntry.text!, score: self.quizLogic.getScore() as NSNumber, date: Date.now as NSDate)
                return
            }else{
                alert = UIAlertController(title: "Warning", message: "Username must be 2-15 character (not accepting emoji)", preferredStyle: .alert)
            }
        }else{
            alert = UIAlertController(title: "Warning", message: "Username can't be empty", preferredStyle: .alert)
        }
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
            self.usernameEntry.text = ""
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateUI(){
        questionLabel.text = quizLogic.getQuestionText().uppercased()
        scoreLabel.text = "Score : \(quizLogic.getScore())"
        progressBar.progress = quizLogic.getProgress()
        questionLabel.layer.cornerRadius = 6
        questionLabel.backgroundColor = UIColor.gray
        startTimer()
    }
    
    @objc func continueGame(){
        isGameRunning = true
    }
    
    func openCamera(){
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSession.Preset.high
        
        let videoDeviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front)
        
        for camera in videoDeviceDiscovery.devices as [AVCaptureDevice] {
            if camera.position == .front {
                cameraDevice = camera
            }
        }
        
        if cameraDevice == nil {
            print("Could not find front camera.")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: cameraDevice!)
            if captureSession!.canAddInput(videoInput) {
                captureSession!.addInput(videoInput)
            } else {
                print("Video input can not be added.")
            }
        } catch {
            print("Something went wrong with the video input.")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession!)
        previewLayer!.frame.size = videoView.frame.size
        previewLayer!.opacity = 0.3
        previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.addSublayer(previewLayer!)
        
        let metadataOutput = AVCaptureMetadataOutput()
        let metaQueue = DispatchQueue(label: "MetaDataSession")
        metadataOutput.setMetadataObjectsDelegate(self, queue: metaQueue)
        if captureSession!.canAddOutput(metadataOutput) {
            captureSession!.addOutput(metadataOutput)
        } else {
            print("Meta data output can not be added.")
        }
        
        metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
        
        captureSession!.startRunning()
    }
    
    func saveNewItem(username : String, score : NSNumber, date: NSDate) {
        usernameEntry.text = ""
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        QuizResults.createInManagedObjectContext(context, username: username, score: score, date: date)
        
        showToast(message: "Score saved", seconds: 1)
    }
}
