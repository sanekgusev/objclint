//
//  objclint
//
//  Created by Alexander Smirnov on 1/19/13.
//  Copyright (c) 2013 Alexander Smirnov. All rights reserved.
//

#import "ObjclintSession.h"
#import "JSValidatorsRunner.h"

#include "clang-utils.h"

@implementation ObjclintSession {
    id<ObjclintCoordinator> _coordinator;
    JSValidatorsRunner*     _jsValidatorsRunner;
    NSString*               _projectPath;
    NSMutableDictionary*    _checkedPaths;
}

#pragma mark - Init&Dealloc

- (id) initWithCoordinator:(id<ObjclintCoordinator>) coordinator {
    self = [super init];
    if (self) {
        _coordinator  = [coordinator retain];
        _projectPath  = [[[NSFileManager defaultManager] currentDirectoryPath] retain];
        _checkedPaths = [[NSMutableDictionary alloc] init];
        
        NSArray* paths = [coordinator JSValidatorsFolderPathsForProjectIdentity: _projectPath];
        _jsValidatorsRunner = [[JSValidatorsRunner alloc] initWithLintsFolderPath: paths[0]];
    }
    return self;
}

- (void)dealloc {
    [_coordinator        release];
    [_projectPath        release];
    [_checkedPaths       release];
    [_jsValidatorsRunner release];
    [super dealloc];
}

#pragma mark - Public

- (BOOL) validateTranslationUnit:(CXTranslationUnit) translationUnit {
    CXCursor cursor = clang_getTranslationUnitCursor(translationUnit);
    
    clang_visitChildrenWithBlock(cursor, ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
        @autoreleasepool {
            
            BOOL visitChilds = NO;
            [self validateCursor: cursor visitChilds: &visitChilds];
            
            if(visitChilds)
                return CXChildVisit_Recurse;
            
            return CXChildVisit_Continue;
            
        }
    });
    
    return !_jsValidatorsRunner.errorsOccured;
}

#pragma mark - Private

- (void) validateCursor:(CXCursor) cursor visitChilds:(BOOL*) visitChilds {
    BOOL safetyTempVar;
    if(!visitChilds)
        visitChilds = &safetyTempVar;
    
    NSString* filePath = [self filePathForCursor: cursor];
    
    if(![self cursorBelongsToProject: cursor] || !filePath) {
        *visitChilds = NO;
        return;
    }
    
    if(!_checkedPaths[filePath]) {
        BOOL coordinatorStatus = [_coordinator checkIfLocation: filePath
                                  wasCheckedForProjectIdentity: _projectPath];
        
        if(coordinatorStatus) {
            _checkedPaths[filePath] = @YES;
        } else {
            // mark as checked globally
            [_coordinator markLocation: filePath
             checkedForProjectIdentity: _projectPath];
            
            // but fully validate in this session
            _checkedPaths[filePath] = @NO;
        }
    }
    
    NSNumber* alreadyChecked = _checkedPaths[filePath];
    
    *visitChilds = !alreadyChecked.boolValue;
    
    if(!alreadyChecked.boolValue) {
        [_jsValidatorsRunner runValidatorsForCursor: cursor];
    }
}

- (BOOL) cursorBelongsToProject:(CXCursor) cursor {
    NSString* filePath = [self filePathForCursor: cursor];
    
    return filePath!=nil && [filePath rangeOfString: _projectPath].location == 0;
}

- (NSString*) filePathForCursor:(CXCursor) cursor {
    char* filePathC = copyCursorFilePath(cursor);
    if(filePathC)
        return [[[NSString alloc] initWithBytesNoCopy: filePathC
                                               length: strlen(filePathC)
                                             encoding: NSUTF8StringEncoding
                                         freeWhenDone: YES] autorelease];
    return nil;
}

@end
