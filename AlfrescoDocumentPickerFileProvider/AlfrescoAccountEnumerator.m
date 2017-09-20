/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/

#import "AlfrescoAccountEnumerator.h"
#import "FileProviderDataManager.h"
#import "AlfrescoFileProviderItem.h"
#import "AlfrescoFileProviderItemIdentifier.h"

@implementation AlfrescoAccountEnumerator

- (instancetype)initWithEnumeratedItemIdentifier:(NSFileProviderItemIdentifier)enumeratedItemIdentifier
{
    if (self = [super init])
    {
        _enumeratedItemIdentifier = enumeratedItemIdentifier;
    }
    return self;
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    /* TODO:
     - inspect the page to determine whether this is an initial or a follow-up request
     
     If this is an enumerator for a directory, the root container or all directories:
     - perform a server request to fetch directory contents
     If this is an enumerator for the active set:
     - perform a server request to update your local database
     - fetch the active set from your local database
     
     - inform the observer about the items returned by the server (possibly multiple times)
     - inform the observer that you are finished with this page
     */
    
    NSMutableArray *enumeratedFolders = [NSMutableArray new];
    NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedFolderIdenfitier:self.enumeratedItemIdentifier];
    RLMResults<FileProviderAccountInfo *> *menuItems = [[FileProviderDataManager sharedManager] menuItemsForAccount:accountIdentifier];
    for(FileProviderAccountInfo *menuItem in menuItems)
    {
        AlfrescoFileProviderItem *item = [[AlfrescoFileProviderItem alloc] initWithAccountInfo:menuItem];
        [enumeratedFolders addObject:item];
    }
    
    [observer didEnumerateItems:enumeratedFolders];
    [observer finishEnumeratingUpToPage:nil];
}

- (void)enumerateChangesForObserver:(id<NSFileProviderChangeObserver>)observer fromSyncAnchor:(NSFileProviderSyncAnchor)anchor
{
    /* TODO:
     - query the server for updates since the passed-in sync anchor
     
     If this is an enumerator for the active set:
     - note the changes in your local database
     
     - inform the observer about item deletions and updates (modifications + insertions)
     - inform the observer when you have finished enumerating up to a subsequent sync anchor
     */
}


@end
