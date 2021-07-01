//
//  DisplayCapture.swift
//  ScreenCapture
//
//  Created by Shanmuganathan on 29/06/21.
//

import Foundation
import CoreGraphics
import AVFoundation

class DisplayCapture {
    var displayStream : CGDisplayStream? = nil
    let backgroundQueue = DispatchQueue(label: "com.screencapture.queue",
                                        qos: .background,
                                        target: nil)
    let encoder = FrameEncoder()
    
    func startCapture()
    {
        displayStream = CGDisplayStream(dispatchQueueDisplay: 0, outputWidth: 1280, outputHeight: 720, pixelFormat: Int32(k32BGRAPixelFormat), properties: nil, queue: backgroundQueue, handler: { (status, code, ioSurface, update) in
            
            if(status == .frameComplete)
            {
                guard let ioSurface = ioSurface else { return }
                self.encoder.encodeFrame(ioSurface: ioSurface)
            }
        })
        displayStream?.start()
    }
    
    
    func stopCapture()
    {
        displayStream?.stop()
        encoder.stopEncoding()
    }
}
