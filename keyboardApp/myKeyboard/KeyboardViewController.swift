//
//  KeyboardViewController.swift
//  myKeyboard
//
//  Created by Austin Wells on 5/4/15.
//  Copyright (c) 2015 Austin Wells. All rights reserved.
//

let SERVER_URL = "http://162.243.242.172:8000"
let pickerData = ["Nature","Technology","Flags","Clocks","Happy","Sad","People"]
import UIKit

class KeyboardViewController: UIInputViewController,UITextFieldDelegate, NSURLSessionDelegate  {
    
    var lastPoint = CGPoint.zeroPoint
    var swiped = false
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var predNum = 0;
    var currentDSID = 1
    var session = NSURLSession()

    @IBOutlet var categoryPicker: UIPickerView!
    @IBOutlet var nextKeyboardButton: UIButton!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var emoji1: UIButton!
    @IBOutlet var emoji2: UIButton!
    @IBOutlet var emoji3: UIButton!
    @IBOutlet var drawingView: UIImageView!
    
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    
        // Add custom view sizing constraints here
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    
        
        categoryPicker = UIPickerView(frame: CGRectMake(230, 0, 230, 90))
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        categoryPicker.backgroundColor = UIColor.whiteColor()
        // create canvas to draw on

        self.drawingView=UIImageView(frame: CGRectMake(0, 0, 230, 230))
        self.drawingView.backgroundColor=UIColor.grayColor()
        self.drawingView.layer.cornerRadius=0
        self.drawingView.layer.borderWidth=1


        self.view.addSubview(self.drawingView)
      
        // Add touch events
        let tap = UITapGestureRecognizer(target: self, action: Selector("start:"))
        drawingView.addGestureRecognizer(tap)
        
        // configure out server components
        var sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.HTTPMaximumConnectionsPerHost = 1
        
        self.session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        
        
        
    
        // create next keyboard button
        self.nextKeyboardButton = UIButton.buttonWithType(.System) as! UIButton
        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), forState: .Normal)
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.nextKeyboardButton.addTarget(self, action: "touchesEnded", forControlEvents: .TouchUpInside)
        //advanceToNextInputMode
        self.view.addSubview(self.nextKeyboardButton)
    
        var nextKeyboardButtonLeftSideConstraint = NSLayoutConstraint(item: self.nextKeyboardButton, attribute: .Right, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        var nextKeyboardButtonBottomConstraint = NSLayoutConstraint(item: self.nextKeyboardButton, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        
        // create clear button 
        self.clearButton = UIButton.buttonWithType(.System) as! UIButton
        self.clearButton.setTitle(NSLocalizedString("Clear", comment: "Title for 'Clear' button"), forState: .Normal)
        self.clearButton.sizeToFit()
        self.clearButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.clearButton.addTarget(self, action: Selector("clearDrawing:"), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(self.clearButton)
        
        // create emoji buttons
        self.emoji1 = UIButton.buttonWithType(.System) as! UIButton
        self.emoji1.setTitle(NSLocalizedString("emoji1", comment: "Title for 'Clear' button"), forState: .Normal)
        self.emoji1.sizeToFit()
        self.emoji1.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.emoji1.addTarget(self, action: Selector("clearDrawing:"), forControlEvents: .TouchUpInside)
        self.view.addSubview(self.emoji1)
        // create emoji buttons
        self.emoji2 = UIButton.buttonWithType(.System) as! UIButton
        self.emoji2.setTitle(NSLocalizedString("emoji2", comment: "Title for 'Clear' button"), forState: .Normal)
        self.emoji2.sizeToFit()
        self.emoji2.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.emoji2.addTarget(self, action: Selector("clearDrawing:"), forControlEvents: .TouchUpInside)
        self.view.addSubview(self.emoji2)
        // create emoji buttons
        self.emoji3 = UIButton.buttonWithType(.System) as! UIButton
        self.emoji3.setTitle(NSLocalizedString("emoji3  ", comment: "Title for 'Clear' button"), forState: .Normal)
        self.emoji3.sizeToFit()
        self.emoji3.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.emoji3.addTarget(self, action: Selector("clearDrawing:"), forControlEvents: .TouchUpInside)
        self.view.addSubview(self.emoji3)
        // add picker
        self.view.addSubview(self.categoryPicker)
        // Add constraints
        self.view.addConstraints([nextKeyboardButtonLeftSideConstraint, nextKeyboardButtonBottomConstraint])
    }
    
    @IBAction func clearDrawing(sender: AnyObject) {
        self.drawingView.image = nil
    }
    
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
            let currentPoint = touch.locationInView(view)
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
        // predict! AND MAKE PREDICTION THINGIES
        let row = self.categoryPicker.selectedRowInComponent(0)
        let value = pickerData[row]
        NSLog("values %@", value)
        let image = getDrawing()
        sendFeatureDrawing(image, label: value)

        
    }
    
    func placePredictions() {
        
    }
    
    //functions to handle drawing onto our screen----------------------------
    func getDrawing() -> UIImage{
        UIGraphicsBeginImageContext(self.drawingView.frame.size)
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext())
        //view.layer.renderInContext(UIGraphicsGetCurrentContext())
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image;
    }
    
    func sendFeatureDrawing(drawing: UIImage, label: String) {
        
        
        //setting up our URL
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = NSURL(string: "\(baseURL)")
        
        //resize the image and encode it into a .png
        let imageData: NSData = UIImagePNGRepresentation(RBResizeImage(drawing, scaleFactor: 0.5))
        let imageData2: String = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        //create our dictionary to upload our feature data with
        let jsonUpload: NSDictionary = ["feature": imageData2, "label": label,"dsid":currentDSID]
        //turn our dictionary into a json object
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
                    
                    NSLog("\n\nJSON Data:\n%@",jsonDictionary)
                    
                    dispatch_async(dispatch_get_main_queue(),{
                        NSLog("YES!")
                    })
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(),{
                       NSLog("Still YES!")
                    })
                }
        })
        
        postTask.resume() // start the task
        
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
    
    @IBAction func start(sender: AnyObject) {
        NSLog("hello")
       self.drawingView.backgroundColor=UIColor.blueColor()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    override func textWillChange(textInput: UITextInput) {
        // The app is about to change the document's contents. Perform any preparation here.
    }

    override func textDidChange(textInput: UITextInput) {
        // The app has just changed the document's contents, the document context has been updated.
    
        var textColor: UIColor
        var proxy = self.textDocumentProxy as! UITextDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.Dark {
            textColor = UIColor.whiteColor()
        } else {
            textColor = UIColor.blackColor()
        }
        self.nextKeyboardButton.setTitleColor(textColor, forState: .Normal)
    }

}

extension KeyboardViewController: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(colorPicker: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 7
    }
}

extension KeyboardViewController: UIPickerViewDelegate {
        func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String!
    {
       
        return pickerData[row]
    }
}
