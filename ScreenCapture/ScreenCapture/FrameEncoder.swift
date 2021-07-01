//
//  FrameEncoder.swift
//  ScreenCapture
//
//  Created by Shanmuganathan on 29/06/21.
//

import Foundation
import VideoToolbox

class FrameEncoder {
    var compressionSession : VTCompressionSession? = nil
    var formatDescription : CMVideoFormatDescription? = nil
    var pixelBuffer : Unmanaged<CVPixelBuffer>?  = nil
    var transport : DisplayTransport = DisplayTransport()
    var frameNumber = 1
    init()
    {
        let encoderSpecification: [CFString: Any] = [ kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder: true
        ]
        let error = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: 1280, height: 720,
            codecType: kCMVideoCodecType_H264,
            //            codecType: kCMVideoCodecType_HEVC,
            encoderSpecification: encoderSpecification as CFDictionary,
            imageBufferAttributes: nil, compressedDataAllocator: nil, outputCallback: nil, refcon: nil, compressionSessionOut: &self.compressionSession)
        
        if error == kVTCouldNotFindVideoEncoderErr { // no HEVC encoder
            return
        }
        guard let compressionSession = compressionSession else {
            return
        }
        // Encoding properties
        let properties:[NSString: NSObject] = [
            kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
            kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_H264_Main_AutoLevel,
            //            kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_HEVC_Main_AutoLevel,
        ]
        let status = VTSessionSetProperties(compressionSession, propertyDictionary: properties as CFDictionary)
        if status != noErr
        {
            let error = NSError(domain:NSOSStatusErrorDomain, code:Int(status), userInfo:nil)
            print("VTSessionSetProperties: \(error.localizedDescription)")
            return
        }
        
        VTCompressionSessionPrepareToEncodeFrames(compressionSession)
    }
    
    func encodeFrame(ioSurface : IOSurfaceRef) {
        guard let compressionSession = compressionSession else {
            return
        }
        let attributes : [AnyHashable: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey : true as AnyObject
        ]
        
        let result = CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault, ioSurface, attributes as CFDictionary, &pixelBuffer)
        guard result == 0 else {
            return
        }
        if let pixelBuffer = pixelBuffer
        {
            let pixelBufferValue = pixelBuffer.takeRetainedValue()
            VTCompressionSessionEncodeFrame(compressionSession, imageBuffer: pixelBufferValue, presentationTimeStamp: CMTime(value: CMTimeValue(frameNumber), timescale: 3), duration: CMTime.invalid, frameProperties: nil, infoFlagsOut: nil) { [self] (compressionstatus, flags, sampleBuffer) in
                guard let sampleBuffer = sampleBuffer else {return}
                let data = didEncodeFrame(frame: sampleBuffer)
                if data.count > 0 {
                    //Send the data to socket
                    transport.sendData(data: data)
                }
            }
            frameNumber = frameNumber + 1
        }
    }
    
    func stopEncoding() {
        guard let compressionSession = compressionSession else {
            return
        }
        VTCompressionSessionCompleteFrames(compressionSession, untilPresentationTimeStamp: CMTime.zero)
    }
    
    public func didEncodeFrame(frame: CMSampleBuffer) -> Data
    {
        print ("Received encoded")
        
        //----AVCC to Elem stream-----//
        let elementaryStream = NSMutableData()
        
        //1. check if CMBuffer had I-frame
        var isIFrame:Bool = false
        let attachmentsArray:CFArray = CMSampleBufferGetSampleAttachmentsArray(frame, createIfNecessary: false)!
        //check how many attachments
        if ( CFArrayGetCount(attachmentsArray) > 0 ) {
            let dict = CFArrayGetValueAtIndex(attachmentsArray, 0)
            let dictRef:CFDictionary = unsafeBitCast(dict, to: CFDictionary.self)
            //get value
            let value = CFDictionaryGetValue(dictRef, unsafeBitCast(kCMSampleAttachmentKey_NotSync, to: UnsafeRawPointer.self))
            if ( value != nil ){
                print ("IFrame found...")
                isIFrame = true
            }
        }
        
        //2. define the start code
        let nStartCodeLength:size_t = 4
        let nStartCode:[UInt8] = [0x00, 0x00, 0x00, 0x01]
        
        //3. write the SPS and PPS before I-frame
        if ( isIFrame == true ){
            let description:CMFormatDescription = CMSampleBufferGetFormatDescription(frame)!
            //how many params
            var numParams:size_t = 0
            //            CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: nil, parameterSetSizeOut: nil, parameterSetCountOut: &numParams, nalUnitHeaderLengthOut: nil)
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: nil, parameterSetSizeOut: nil, parameterSetCountOut: &numParams, nalUnitHeaderLengthOut: nil)
            
            //write each param-set to elementary stream
            print("Write param to elementaryStream ", numParams)
            for i in 0..<numParams {
                var parameterSetPointer:UnsafePointer<UInt8>? = nil
                var parameterSetLength:size_t = 0
                //                CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(description, parameterSetIndex: i, parameterSetPointerOut: &parameterSetPointer, parameterSetSizeOut: &parameterSetLength, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
                CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: i, parameterSetPointerOut: &parameterSetPointer, parameterSetSizeOut: &parameterSetLength, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
                elementaryStream.append(nStartCode, length: nStartCodeLength)
                elementaryStream.append(parameterSetPointer!, length: parameterSetLength)
            }
        }
        
        //4. Get a pointer to the raw AVCC NAL unit data in the sample buffer
        var blockBufferLength:size_t = 0
        var bufferDataPointer: UnsafeMutablePointer<Int8>? = nil
        CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(frame)!, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &blockBufferLength, dataPointerOut: &bufferDataPointer)
        print ("Block length = ", blockBufferLength)
        
        //5. Loop through all the NAL units in the block buffer
        var bufferOffset:size_t = 0
        let AVCCHeaderLength:Int = 4
        while (bufferOffset < (blockBufferLength - AVCCHeaderLength) ) {
            // Read the NAL unit length
            var NALUnitLength:UInt32 =  0
            memcpy(&NALUnitLength, bufferDataPointer! + bufferOffset, AVCCHeaderLength)
            //Big-Endian to Little-Endian
            NALUnitLength = CFSwapInt32(NALUnitLength)
            if ( NALUnitLength > 0 ){
                print ( "NALUnitLen = ", NALUnitLength)
                // Write start code to the elementary stream
                elementaryStream.append(nStartCode, length: nStartCodeLength)
                // Write the NAL unit without the AVCC length header to the elementary stream
                elementaryStream.append(bufferDataPointer! + bufferOffset + AVCCHeaderLength, length: Int(NALUnitLength))
                // Move to the next NAL unit in the block buffer
                bufferOffset += AVCCHeaderLength + size_t(NALUnitLength);
                print("Moving to next NALU...")
            }
        }
        print("Read completed...")
        return elementaryStream as Data
    }
}
