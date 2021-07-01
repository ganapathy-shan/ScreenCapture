//
//  CVSampleBuffer+Extension.swift
//  ScreenCapture
//
//  Created by Shanmuganathan on 30/06/21.
//

import CoreMedia

#if os(macOS)
import Accelerate
#endif

extension CMSampleBuffer {
    
    var dataBuffer: CMBlockBuffer? {
        get {
            CMSampleBufferGetDataBuffer(self)
        }
        set {
            _ = newValue.map {
                CMSampleBufferSetDataBuffer(self, newValue: $0)
            }
        }
    }
    
    var data: Data? {
        dataBuffer?.data
    }
    
    var imageBuffer: CVImageBuffer? {
        CMSampleBufferGetImageBuffer(self)
    }
}
