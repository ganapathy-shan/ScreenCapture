ScreenCapture
=============

Overview
--------

The **ScreenCapture** project captures the main display, encodes the video into H.264, and transmits the encoded stream over a network socket using **CocoaAsyncSocket**.

### Features

-   Captures the main display using `CGDisplayStream`.
-   Compresses video using **H.264** via **VideoToolbox**.
-   Sends the encoded video stream through a socket.

* * * * *

Setup Instructions
------------------

### Prerequisites

-   macOS with Xcode installed.
-   CocoaPods installed (`sudo gem install cocoapods`).

### Steps to Build

1.  Navigate to the `ScreenCapture` project directory.
2.  Run the following command to install dependencies:
    `pod install`
3.  Open the `.xcworkspace` file in Xcode.
4.  Build and run the project.

### Troubleshooting

If you encounter build issues:

1.  Remove the Pods directory and lock file:
    `rm -rf Pods/ Podfile.lock`
2.  Reinstall CocoaPods:
    `pod install`

* * * * *

How to Use
----------

1.  Launch the **ScreenCapture** app.
2.  The app starts capturing the main display and encoding the content in real-time.
3.  The encoded H.264 stream is sent over the network to the configured IP address and port using **CocoaAsyncSocket**.

* * * * *

Data Flow
---------

1.  Captures the main display via `CGDisplayStream`.
2.  Compresses frames to H.264 using **VideoToolbox**.
3.  Streams the encoded video over a network socket.
