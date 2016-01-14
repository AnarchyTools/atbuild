//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

import Foundation

class SizedQueue<ElementType> {
    var items: [ElementType] = []
    let maximumNumberOfItems: Int
    
    private var lastIndex: Int = 0
    
    init(maximumNumberOfItems: Int = 10) {
        self.maximumNumberOfItems = maximumNumberOfItems
    }
    
    
}