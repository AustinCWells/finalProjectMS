

import UIKit

//globals to set our server URL and standard option
let SERVER_URL = "http://162.243.242.172:8000"
let predictionOptions = ["Nature","Technology","Flags","Clocks","Happy","Sad","People", "#", "!", "(", ")", "@", "$", "^", "%", "&", "*"]
let predictText = ["Nature" : "⭐️🌏☔️☀️🌝🌞🌱🌴🌲🌾🌿🌺🌸🌷🍀🌹🍃🍁",
    "Technology" : "🎥📷📹💽📀💿📼💾💻📱📞📟📠📡📺📻🔊🔉",
    "Flags" : "⚐⚑📪🎌📫🏁🚩📬📭⛳️",
    "Clocks" : "🕐🕑🕓🕔⏰🕡🕞🕝🕤",
    "Happy" : "😍😜😝😋😘😁😂😆😅😃😊😄😏😉😸😺😹😀😎😇",
    "Sad" : "😧😦😟😮😯😫😖😭😞😩😒😰😵",
    "People" : "🙆🙅🙎💆👰👎👍👀✊👲💂👶👳👩👨👧👦",
    "#" : "#", "!": "!", "(" : "(", ")" : "(", "@" : "@", "$": "$", "^": "^", "%" : "%", "&" : "&", "*": "*"]

class KeyboardViewController: UIInputViewController, NSURLSessionDelegate {
    
    //view vars for master view manipulation
    var customInterface: UIView!
    var uploadState = true
    
    //drawing vars for drawing configurations
    var lastPoint = CGPoint.zeroPoint
    var swiped = false
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    
    //networking vars
    var session = NSURLSession()
    
    //outlets from main .XIB layout file
    @IBOutlet weak var drawingView: UIImageView!
    @IBOutlet weak var scrollviewButtons: UIImageView!
    @IBOutlet weak var upload: UIBarButtonItem!
    @IBOutlet weak var buttonScroll: UIScrollView!
    
    //loading our .xib into memory to be used as our main view
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        var nib = UINib(nibName: "CustomKeyboard", bundle: nil)
        let objects = nib.instantiateWithOwner(self, options: nil)
        customInterface = objects[0] as! UIView
    }
    
    //not sure why xcode requires us to have this function...?
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //for any custom constaintes
    override func updateViewConstraints() {
        super.updateViewConstraints()
        // Add custom view sizing constraints here
    }
    
    
    //setting our .xib as our main view (.xib was loading in the init function)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(customInterface)
        
        self.lastPoint = CGPoint.zeroPoint
        
        // set upload button

       
        
        //connecting to our server
        var sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.HTTPMaximumConnectionsPerHost = 1
        
        self.session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        
        
        //scrolling pageview
        buttonScroll.showsVerticalScrollIndicator = true
        buttonScroll.indicatorStyle = .Default
        buttonScroll.backgroundColor = UIColor.whiteColor()
        
    }
    

    
    override func textWillChange(textInput: UITextInput) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(textInput: UITextInput) {
        
    }
    
    //FUNCTIONS TO ENABLE BUTTON PRESSED TAGGED FORM OUR .XIB
    
    
    @IBAction func spacePress(sender: UIBarButtonItem) {
        var proxy = textDocumentProxy as! UITextDocumentProxy
        proxy.insertText(" ")
    }
    
    
    @IBAction func backspacePress(sender: AnyObject) {
        var proxy = textDocumentProxy as! UITextDocumentProxy
        proxy.deleteBackward()
    }
    
    @IBAction func prevKeyboardPress(sender: AnyObject) {
        self.advanceToNextInputMode()
    }
    
    @IBAction func clearPressed(sender: AnyObject) {
        self.drawingView.image = nil
    }
    
    @IBAction func uploadPressed(sender: AnyObject) {
        if uploadState == true {
             upload.tintColor = UIColor(red:29.0/255.0, green:158.0/255.0, blue:253.0/255.0, alpha:1.0)
            uploadState = false
        }else{
            upload.tintColor = UIColor.grayColor()
           
            uploadState = true
        }
    }
    
    //FUNCTIONS TO ENABLE DRAWING ON THE IMAGEVIEW LABELED DRAWING VIEW***************
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        if fromPoint.x == 0 && fromPoint.y == 0 {
            return
        }
        // 1
        UIGraphicsBeginImageContext( drawingView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        drawingView.image?.drawInRect(CGRect(x: 0, y: 0, width: drawingView.frame.size.width,  height: drawingView.frame.size.height))
        
        // 2
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        // 3
        CGContextSetLineCap(context, kCGLineCapRound)
        CGContextSetLineWidth(context, brushWidth)
        CGContextSetBlendMode(context, kCGBlendModeNormal)
        
        // 4
        CGContextStrokePath(context)
        
        // 5
        drawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        drawingView.alpha = opacity
        UIGraphicsEndImageContext()
        
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        // 6
        swiped = true
        if let touch = touches.first as? UITouch {
            let currentPoint = touch.locationInView(drawingView)
            drawLineFrom(lastPoint, toPoint: currentPoint)
            self.drawingView.backgroundColor=UIColor.whiteColor()
            // 7
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if !swiped {
            // draw a single point
            drawLineFrom(lastPoint, toPoint: lastPoint)
            
        }
        
        self.lastPoint = CGPoint.zeroPoint
        
        let image = getDrawing()
        
        //predict our drawing with the image provided
        predictDrawing(image)
        
    }
    
    //functions to handle session post and get requests***************************
    
    func predictDrawing(drawing: UIImage){
        
        //setting up our URL
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = NSURL(string: "\(baseURL)")
        
        //converting our image into a format we can send in a json object
        let imageData: NSData = UIImagePNGRepresentation(RBResizeImage(drawing, scaleFactor: 0.5))
        let imageData_64: String = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        var shouldUpload = 0;
        
        if uploadState == true {
            shouldUpload = 1
        }
        
        //create our dictionary to upload our feature data with and convert it into a json object
        let jsonUpload: NSDictionary = ["feature": imageData_64, "dsid":1, "upload": shouldUpload]
        var jsonError: NSError? = nil
        var requestBody:NSData? = NSJSONSerialization.dataWithJSONObject(jsonUpload, options:NSJSONWritingOptions.PrettyPrinted, error:&jsonError);
        
        // create a custom HTTP POST request
        var request = NSMutableURLRequest(URL: postUrl!)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        let postTask : NSURLSessionDataTask = self.session.dataTaskWithRequest(request,
            completionHandler:{(data, response, error) in
                if((response) != nil){
                    //unpacking needed data
                    NSLog("Response:\n%@",response)
                    var jsonError: NSError?
                    var jsonDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as! NSDictionary
                    print(jsonDictionary)
                    
                    let predictionLabelText = jsonDictionary.valueForKey("prediction") as! String
                    var myIcons = predictText[predictionLabelText]!
                    
                    //changing our UI on the main thread
                    dispatch_async(dispatch_get_main_queue(),{
                        let scrollingView = self.emojiButtonsView(CGSizeMake(40.0, 40.0), icons: myIcons)
                        self.buttonScroll.contentSize = scrollingView.frame.size
                        self.buttonScroll.addSubview(scrollingView)
                        //set up the scroll view here
                    })
                }else{
                    dispatch_async(dispatch_get_main_queue(),{
                        //set a no connection icon since we did not get a response form the server
                        NSLog("NO RESPONSE FROM THE SERVER")
                        let image = UIImage(named: "oops.png")
                        self.drawingView.image = image
                        
                    })
                }
                
                
        })
        
        postTask.resume() // start the task
        
        
    }
    
    //functions to handle drawing onto our screen----------------------------
    func getDrawing() -> UIImage{
        UIGraphicsBeginImageContext(self.drawingView.frame.size)
        self.drawingView.layer.renderInContext(UIGraphicsGetCurrentContext())
        //self.view.layer.renderInContext(UIGraphicsGetCurrentContext())
        //view.layer.renderInContext(UIGraphicsGetCurrentContext())
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //for debugging purposed (able to see hwta exactly the image we are rendering above is)
        //UIImageWriteToSavedPhotosAlbum(image, self, Selector("image:didFinishSavingWithError:contextInfo:"), nil)
        
        return image;
    }
    
    func emojiButtonPressed(sender:UIButton){
        var proxy = textDocumentProxy as! UITextDocumentProxy
        proxy.insertText(sender.titleLabel!.text!)
    }
    
    func emojiButtonsView(buttonSize:CGSize, icons: String) -> UIView {
        //creates color buttons in a UIView
        let buttonCount = count(icons)
        let buttonView = UIView()
        buttonView.frame.origin = CGPointMake(0,0)
        let padding = CGSizeMake(0, 10)
        buttonView.frame.size.height = (buttonSize.height + padding.height) * CGFloat(buttonCount)
        buttonView.frame.size.width = (buttonSize.width +  4.0 * padding.width)
        
        var buttonPosition = CGPointMake(padding.height * 0.5, padding.width)
        let buttonIncrement = buttonSize.height + padding.height
        
        for i in 0...(buttonCount - 1)  {
            var button = UIButton.buttonWithType(.Custom) as! UIButton
            button.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            button.frame.size = buttonSize
            button.setTitle(" " + String(icons[advance(icons.startIndex, i)]) + " ", forState: UIControlState.Normal)
            button.backgroundColor = UIColor.whiteColor()
            button.frame.origin = buttonPosition
            buttonPosition.y = buttonPosition.y + buttonIncrement
            button.addTarget(self, action: "emojiButtonPressed:", forControlEvents: .TouchUpInside)
            buttonView.addSubview(button)
        }
        
        return buttonView
    }
    
    
    //functions to handle cerating our scroll view of emojis programatically
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo: UnsafePointer<()>) {
        NSLog("This image has been saved to your Camera Roll successfully")
    }
    
    //this function is adapted from https://gist.github.com/hcatlin/180e81cd961573e3c54d
    //it reszes an image based on an input scale factor
    func RBResizeImage(image: UIImage, scaleFactor: CGFloat) -> UIImage {
        let size = image.size
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        newSize = CGSizeMake(size.width * scaleFactor,  size.height * scaleFactor)
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}