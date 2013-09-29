Pronounced “Super Ogress” (as in a female Ogre who is also a super-hero),
SuProgress is a utlitity library to show a iOS-7-Safari-style progress bar under
the UINavigationBar for your app.

Crucially SuProgress is a drop-in library for common progress types eg.
NSURLConnection, UIWebView, AFNetworking, and NSProgress.

![gif](http://methylblue.com/images/SuProgressExample.gif)

SuProgress was made by [Mobile Makers][mm], Chicago, an eight week intense
learning experience that will take you from beginner to professional iOS
developer.

SuProgress was mostly authored by [Max Howell][mxcl], a splendid chap.

Usage
-----
SuProgress is super easy to use:

```objc
[viewController SuProgressURLConnectionsCreatedInBlock:^{
	[NSURLConnection connectionWithRequest:request delegate:self];
}];
```

Any NSURLConnections created in that block have their progress proxied to the
SuProgressBarView, which we also create and maintain for you.

Of course this means **any** frameworks or methods you call that operate via
NSURLConnection will have their progress proxied. For example, the Facebook SDK:

```objc
[viewController SuProgressURLConnectionsCreatedInBlock:^{
	[FBRequestConnection startWithGraphPath:@"/me" completionHandler:foo];
}];
```

Neat, right?

Here’s how to display progress for a UIWebView:

```objc
[viewController SuProgressForWebView:webView]
```

Requirements
------------
* ARC
* iOS >= 5

Example.xcodeproj
-----------------
The example only builds with Xcode 5.

License
=======
Copyright 2013, Max Howell, all rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[mm]:http://mobilemakers.co
[mxcl]:http://mxcl.github.io
