//
//  ViewController.swift
//  Interpherometr
//
//  Created by Hena Sofronov on 5/9/16.
//  Copyright © 2016 Hena Sofronov. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    let images = [UIImage(named: "1_1"),
                  UIImage(named: "1_2"),
                  UIImage(named: "2_1"),
                  UIImage(named: "2_2"),
                  UIImage(named: "3_1"),
                  UIImage(named: "3_2"),
                  UIImage(named: "4_1"),
                  UIImage(named: "4_2"),
                  UIImage(named: "rgb")]
    let imageProcessor = ImageProcessor()
    var imageIndex: Int = 0 {
        didSet {
            if (imageIndex < 0) {
                imageIndex = 0
            }
            if (imageIndex > self.images.count - 1) {
                imageIndex = self.images.count - 1
            }
            self.imageView.image = self.images[self.imageIndex]
            self.imageProcessor.image = self.images[self.imageIndex]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageIndex = 0;
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let destinationVC = segue.destinationViewController as? ReliefViewController else {
            return
        }
        destinationVC.image = self.imageProcessor.pathImage
    }

    @IBAction func prevButtonPressed(sender: AnyObject) {
        self.imageIndex -= 1
    }
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        self.imageIndex += 1
    }

    @IBAction func imageViewTap(sender: AnyObject) {
        guard let locationInView = (sender as? UITapGestureRecognizer)?.locationInView(self.imageView) else {
            return
        }
        guard let image = self.imageView.image else {
            return
        }
        let imageRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.imageView.bounds)
        let locationInImageRect = CGPoint(x: locationInView.x - imageRect.origin.x, y: locationInView.y - imageRect.origin.y)
        let locationInImage = CGPoint(x: locationInImageRect.x / imageRect.size.width * image.size.width,
                                      y: locationInImageRect.y / imageRect.size.height * image.size.height)
        
        self.imageProcessor.startFindingFromPoint(locationInImage)
        self.imageView.image = self.imageProcessor.imageWithLines
    }
}

