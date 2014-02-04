//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "SuProgressManager.h"

@interface SuProgressManager ()

@property NSMutableArray *singleUses;

@end

@implementation SuProgressManager

static SuProgressManager *sharedManager;

+ (id)currentManager
{
    @synchronized(sharedManager) {
        return sharedManager;
    }
}

+ (void)setCurrentManager:(SuProgressManager *)manager
{
    @synchronized(sharedManager) {
        sharedManager = manager;
    }
}

+ (id)managerWithDelegate:(id<SuProgressManagerDelegate>)delegate
{
    SuProgressManager *king = [SuProgressManager new];
    king->_delegate = delegate;
    king->_ogres = [NSMutableArray new];
    king->_singleUses = [NSMutableArray new];
    return king;
}

- (void)addOgre:(SuProgress *)ogre singleUse:(BOOL)singleUse
{
    ogre.delegate = self;
    [_ogres addObject:ogre];
    
    if (singleUse) {
        [self.singleUses addObject:ogre];
    }
}

- (BOOL)allFinished
{
    for (SuProgress *ogre in _ogres) {
        if (!ogre.finished) {
            return NO;
        }
    }
    
    return YES;
}

- (void)progressed:(SuProgress *)ogre
{
    if (ogre.finished && self.allFinished) {
        [self.delegate finished];
        [self.ogres removeObjectsInArray:self.singleUses];
        [self.ogres makeObjectsPerformSelector:@selector(reset)];
        [self.singleUses removeAllObjects];
    } else {
        float progress = 0;
        for (SuProgress *ogre in self.ogres) {
            progress += ogre.progress;
        }
        
        progress /= self.ogres.count;
        progress *= 0.95;  // only reach 100% when all ogres are finished
        [self.delegate progressed:progress];
    }
}

@end
