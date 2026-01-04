OpenParsec is a simple, open-source Parsec client for iOS/iPadOS written in Swift using the SwiftUI framework and the Parsec SDK.

> [!WARNING]
> This is an opinionated personal fork for my personal use. I am not intending for support of older iOS/iPadOS versions and current min target is set to 26.
> Feel free to use at your own risk, I do not intend to merge my changes back to upstream, nor take pull requests.

Before building, make sure you have the Parsec SDK framework symlinked or copied to the `Frameworks` folder. Builds were tested on Xcode Version 12.5.

## Touch Control
You can set the touch mode you want to use in settings. Touchpad mode and direct touch mode are supported.

When streaming, you can tap with 3 fingers to bring up the on-screen keyboard.

## Mouse & keyboard
USB mouse & keyboard are supported. 

## Game Controllers
When streaming, press any trigger button in your controller and parsec will recognize it. Make sure to configure the host properly (install virtual USB driver etc.) before using game controllers.

## Lag / Low Bitrate Issue
If you encounter lags from nowhere or your bitrate hardly goes over 10 Mbps, download Steam Link and do a network test. If you see constant lag spike in the graph, then it's a problem with Apple and there's little we can do to solve this problem. See [here](https://github.com/moonlight-stream/moonlight-ios/issues/627) for more disscussion. 

If you can't change your wireless router's channel to 149 like me, my personal experience is that you can try to power off the device you are using to stream as well as any nearby Apple devices, especially Mac, then only power on the device you are using to stream and do the aforementioned network test again. You can turn on other devices if the lag spike is gone and it may sustain for couple hours or days.
