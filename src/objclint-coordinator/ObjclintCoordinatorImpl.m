//
//  ObjclintCoordinatorImpl.m
//  objclint
//
//  Created by Alexander Smirnov on 12/9/12.
//  Copyright (c) 2012 Alexander Smirnov. All rights reserved.
//

#import "ObjclintCoordinatorImpl.h"

// TODO: AOP for 'updateLastActionDate'.

@implementation ObjclintCoordinatorImpl {
    NSMutableDictionary* _sessionsByProject;
    NSMutableDictionary* _validatorsFolderPathsForProject;
    NSMutableDictionary* _issuesByProject;
}

#pragma mark - Init&Dealloc

- (id)init {
    self = [super init];
    if (self) {
        _sessionsByProject               = @{}.mutableCopy;
        _validatorsFolderPathsForProject = @{}.mutableCopy;
        _issuesByProject                 = @{}.mutableCopy;
    }

    return self;
}

- (void)dealloc {
    
    [_lastActionDate                  release];
    [_sessionsByProject               release];
    [_validatorsFolderPathsForProject release];
    [_issuesByProject                 release];
    
    [super dealloc];
}

#pragma mark - ObjclintSessionManagerProtocol

- (void) clearSessionForProjectIdentity:(NSString*) projectIdentity {
    [self updateLastActionDate];
    
    if(!projectIdentity)
        return;

    [_sessionsByProject removeObjectForKey: projectIdentity];
    [_validatorsFolderPathsForProject removeObjectForKey: projectIdentity];
}

- (void)addJSValidatorsFolderPath:(NSString*) folderPath forProjectIdentity:(NSString*) projectIdentity {
    [self updateLastActionDate];
    
    if(!projectIdentity)
        return;
    
    if(folderPath) {
        NSMutableArray* paths = _validatorsFolderPathsForProject[projectIdentity];
        if(!paths) {
            paths = [NSMutableArray array];
            _validatorsFolderPathsForProject[projectIdentity] = paths;
        }
        if(NO == [paths containsObject: folderPath])
            [paths addObject: folderPath];
    }
}

- (NSArray*) JSValidatorsFolderPathsForProjectIdentity:(NSString*) projectIdentity {
    [self updateLastActionDate];

    if(!projectIdentity)
        return nil;
    
    return _validatorsFolderPathsForProject[projectIdentity];
}

- (BOOL) checkIfLocation:(NSString*) location wasCheckedForProjectIdentity:(NSString*) projectIdentity {
    [self updateLastActionDate];
    
    if(!location)
        return NO;

    NSMutableSet* projectLocations = _sessionsByProject[projectIdentity];
    return [projectLocations containsObject: location];
}

- (void) markLocation:(NSString*) location checkedForProjectIdentity:(NSString*) projectIdentity {
    [self updateLastActionDate];
    
    if(!location)
        return;

    NSMutableSet* projectLocations = _sessionsByProject[projectIdentity];

    if (!projectLocations) {
        projectLocations = [NSMutableSet set];
        _sessionsByProject[projectIdentity] = projectLocations;
    }

    [projectLocations addObject: location];
}

- (void) reportIssue:(ObjclintIssue*) issue forProjectIdentity:(NSString*) projectIdentity {
    [self updateLastActionDate];
    
    if(!issue)
        return;
    
    NSMutableArray* issues = _issuesByProject[projectIdentity];
    if(!issues) {
        issues = [NSMutableArray array];
        _issuesByProject[projectIdentity] = issues;
    }
    
    [issues addObject: issue];
}

- (NSArray*) issuesForProjectIdentity:(NSString*) projectIdentity {
    return _issuesByProject[projectIdentity] ?: [NSArray array];
}

#pragma mark - Private

- (void) updateLastActionDate {
    [_lastActionDate autorelease];
    _lastActionDate = [[NSDate date] retain];
}

@end
