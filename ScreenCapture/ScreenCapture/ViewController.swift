//
//  ViewController.swift
//  ScreenCapture
//
//  Created by Shanmuganathan on 29/06/21.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    let displayCapture = DisplayCapture()
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.isEnabled = true
        stopButton.isEnabled = false

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func startCapture(_ sender: NSButton) {
        
        startButton.isEnabled = false
        stopButton.isEnabled = true
        displayCapture.startCapture()
    }
    
    @IBAction func stopCapture(_ sender: Any) {
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
        displayCapture.stopCapture()
    }
}

