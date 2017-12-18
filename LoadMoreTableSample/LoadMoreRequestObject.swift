//
//  LoadMoreRequestObject.swift
//  LoadMoreTableSample
//
//  Created by maru on 2017/12/18.
//
//

import UIKit

class LoadMoreRequestObject<T> {
    var currentPage: Int
    var totalCount: Int
    var limit: Int
    var isRequesting: Bool
    var isScrolling = false {
        didSet {
            if !isScrolling && pendingProcess != nil {
                pendingProcess?()
                pendingProcess = nil
            }
        }
    }
    var hidesFooter: Bool
    var sourceObjects: [T]
    var pendingProcess: (() -> Void)?
    var fetchSourceObjects: (_ completion: @escaping (_ sourceObjects: [T], _ hasNext: Bool) -> ()) -> ()
    
    init(currentPage: Int = 0,
         totalCount: Int = 0,
         limit: Int = 20,
         isRequesting: Bool = false,
         isScrolling: Bool = false,
         hidesFooter: Bool = false,
         sourceObjects: [T] = [T](),
         pendingProcess: (() -> Void)? = nil,
         fetchSourceObjects: @escaping (_ completion: @escaping (_ sourceObjects: [T], _ hasNext: Bool) -> ()) -> () = { _ in }
        ) {
        self.currentPage = currentPage
        self.totalCount = totalCount
        self.limit = limit
        self.isRequesting = isRequesting
        self.isScrolling = isScrolling
        self.hidesFooter = hidesFooter
        self.sourceObjects = sourceObjects
        self.pendingProcess = pendingProcess
        self.fetchSourceObjects = fetchSourceObjects
    }
    
    var lastPage: Int {
        var _page = 0
        while limit + _page * limit < totalCount {
            _page += 1
        }
        return _page
    }
    
    var hasNext: Bool {
        return currentPage <= lastPage
    }
}
