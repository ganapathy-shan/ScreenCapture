# ScreenCapture

- Captures main display using CGDisplayStream.
- Encode using Video toolbox (H264 Encoding)
- Send the elementary stream to network trnasport using CocoaAsynSocket.


Build instruction: 
Run pod install from project folder before building. 
If any issues while building the project, run rm -rf Pods/ Podfile.lock and the run pod install.
