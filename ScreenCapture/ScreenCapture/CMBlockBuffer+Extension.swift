//
//  CMBlockBuffer+Extension.swift
//  ScreenCapture
//
//  Created by Shanmuganathan on 30/06/21.
//

import CoreMedia

extension CMBlockBuffer {
    var dataLength: Int {
        CMBlockBufferGetDataLength(self)
    }
    
    var data: Data? {
        var length: Int = 0
        var buffer: UnsafeMutablePointer<Int8>?
        guard CMBlockBufferGetDataPointer(self, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &buffer) == noErr else {
            return nil
        }
        return Data(bytes: buffer!, count: length)
    }
}
