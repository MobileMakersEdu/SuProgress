//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "SuProgressNSURLConnection.h"

@interface SuProgressNSURLConnection()

@property long long totalBytes;

@end

@implementation SuProgressNSURLConnection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)rsp
{
    if (rsp.statusCode == 200) {
        self.totalBytes = [rsp.allHeaderFields[@"Content-Length"] intValue];
        if ([rsp.allHeaderFields[@"Content-Encoding"] isEqual:@"gzip"]) {
            // Oh man, we get the data back UNgzip'd, and the total figure is
            // for bytes of content to expect! So we'll guestimate and x4 it
            // FIXME anyway to get a better solution? Probably not without private API
            // or AFNetworking.
            self.totalBytes *= 4;
        }
    } else {
        #warning TODO: We are not yet throwing a proper error here.
    }
    
    self.trickled += 0.1;
    [self.delegate progressed:self];
    
    if ([self.endDelegate respondsToSelector:_cmd]) {
        [self.endDelegate connection:connection didReceiveResponse:rsp];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (self.totalBytes) {
        self.properProgress += (float)data.length / (float)(self.totalBytes);
    } else {
        self.trickled += 0.05;
    }
    
    void (^block)(void) = ^{
        [self.delegate progressed:self];
    };
    
    if ([NSThread currentThread] != [NSThread mainThread]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:block];
    } else {
        block();
    }
    
    if ([self.endDelegate respondsToSelector:_cmd]) {
        [self.endDelegate connection:connection didReceiveData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.finished = YES;
    [self.delegate progressed:self];
    
    if ([self.endDelegate respondsToSelector:_cmd]) {
        [self.endDelegate connection:connection didFailWithError:error];
    }
}

- (void)connectionDidFinishLoading:(id)connection
{
    self.finished = YES;
    [self.delegate progressed:self];
    
    if ([self.endDelegate respondsToSelector:_cmd]) {
        [self.endDelegate connectionDidFinishLoading:connection];
    }
}

@end