//
//  LoadMoreProvider.swift
//  LoadMoreTableSample
//
//  Created by maru on 2017/12/18.
//
//

import UIKit

protocol LoadMoreProvider: class {
    
    associatedtype DataView: UIScrollView
    associatedtype DataType
    
    var loadMoreDataView: DataView { get }
    var requestObject: LoadMoreRequestObject<DataType> { get set }
    func refreshData(immediately: Bool)
    var loadMoreMainSection: Int { get }
    var loadMoreFooterSection: Int { get }
    func updateDataView(reload: Bool, hasNext: Bool)
    func updateFooter(show: Bool)
    func loadMore(reload: Bool)
}

extension LoadMoreProvider {
    
    func loadMore(reload: Bool) {
        guard !requestObject.isRequesting else { return }
        requestObject.isRequesting = true
        
        if reload {
            requestObject.currentPage = 0
        }
        let oldDataCount = requestObject.sourceObjects.count
        
        self.requestObject.fetchSourceObjects() { [weak self] sourceObjects, hasNext in
            guard let strongSelf = self else { return }
            
            if oldDataCount == strongSelf.requestObject.sourceObjects.count {
                strongSelf.requestObject.sourceObjects.append(contentsOf: sourceObjects)
            }
            
            if strongSelf.requestObject.isScrolling == true {
                if strongSelf.requestObject.pendingProcess == nil {
                    strongSelf.requestObject.pendingProcess = {
                        strongSelf.updateDataView(reload: reload, hasNext: hasNext)
                    }
                }
            } else {
                strongSelf.updateDataView(reload: reload, hasNext: hasNext)
            }
            
            strongSelf.requestObject.isRequesting = false
        }
    }
    
}


// UITableViewの追加読み込みの拡張

extension LoadMoreProvider where DataView == UITableView {
    
    func refreshData(immediately: Bool) {
        requestObject.sourceObjects.removeAll()
        
        if immediately {
            requestObject.isScrolling = false
        }
        
        DispatchQueue.main.async {
            if immediately {
                self.loadMoreDataView.reloadData()
                self.updateFooter(show: true)
            } else {
                self.loadMore(reload: true)
            }
        }
    }
    
    func updateDataView(reload: Bool, hasNext: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            UIView.performWithoutAnimation {
                let newDataCount = strongSelf.requestObject.sourceObjects.count
                let currentDataCount = strongSelf.loadMoreDataView.numberOfRows(inSection: strongSelf.loadMoreMainSection)
                if currentDataCount < newDataCount {
                    strongSelf.loadMoreDataView.insertRows(at: Array(currentDataCount..<newDataCount).map { IndexPath(row: $0, section: strongSelf.loadMoreMainSection) }, with: .none)
                    
                } else {
                    strongSelf.loadMoreDataView.deleteRows(at: Array(newDataCount..<currentDataCount).map { IndexPath(row: $0, section: strongSelf.loadMoreMainSection) }, with: .none)
                }
                
                if reload {
                    strongSelf.loadMoreDataView.reloadRows(at: Array(0..<newDataCount).map { IndexPath(row: $0, section: strongSelf.loadMoreMainSection) }, with: .none)
                }
            }

            if !hasNext {
                strongSelf.updateFooter(show: false)
            } else {
                strongSelf.updateFooter(show: true)
            }
        }
    }
    
    func updateFooter(show: Bool) {
        guard requestObject.pendingProcess == nil else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if show && strongSelf.requestObject.hidesFooter {
                strongSelf.requestObject.hidesFooter = false
                strongSelf.loadMoreDataView.insertRows(at: [IndexPath(row: 0, section: strongSelf.loadMoreFooterSection)], with: .none)
            } else if !show && !strongSelf.requestObject.hidesFooter {
                strongSelf.requestObject.hidesFooter = true
                strongSelf.loadMoreDataView.deleteRows(at: [IndexPath(row: 0, section: strongSelf.loadMoreFooterSection)], with: .none)
            } else if show && !strongSelf.requestObject.hidesFooter {
                strongSelf.loadMoreDataView.reloadData()
            }
        }
    }

}


// UITableViewの追加読み込みの拡張

extension LoadMoreProvider where DataView == UICollectionView {
    
    func refreshData(immediately: Bool) {
        requestObject.sourceObjects.removeAll()
        
        if immediately {
            requestObject.isScrolling = false
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if immediately {
                strongSelf.loadMoreDataView.reloadData()
                strongSelf.updateFooter(show: true)
            } else {
                strongSelf.loadMore(reload: true)
            }
        }
    }
    
    func updateDataView(reload: Bool, hasNext: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                let newDataCount = strongSelf.requestObject.sourceObjects.count
                let currentDataCount = strongSelf.loadMoreDataView.numberOfItems(inSection: strongSelf.loadMoreMainSection)
                if currentDataCount < newDataCount {
                    strongSelf.loadMoreDataView.insertItems(at: Array(currentDataCount..<newDataCount).map { IndexPath(row: $0, section: strongSelf.loadMoreMainSection) })
                    
                } else {
                    strongSelf.loadMoreDataView.deleteItems(at: Array(newDataCount..<currentDataCount).map { IndexPath(row: $0, section: strongSelf.loadMoreMainSection) })
                }
                
                if reload {
                    strongSelf.loadMoreDataView.reloadItems(at: Array(0..<newDataCount).map { IndexPath(row: $0, section: strongSelf.loadMoreMainSection) })
                }
            }
            
            if !hasNext {
                strongSelf.updateFooter(show: false)
            } else {
                strongSelf.updateFooter(show: true)
            }
        }
    }
    
    func updateFooter(show: Bool) {
        guard requestObject.pendingProcess == nil else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if show && strongSelf.requestObject.hidesFooter {
                strongSelf.requestObject.hidesFooter = false
                strongSelf.loadMoreDataView.insertItems(at: [IndexPath(item: 0, section: strongSelf.loadMoreFooterSection)])
            } else if !show && !strongSelf.requestObject.hidesFooter {
                strongSelf.requestObject.hidesFooter = true
                strongSelf.loadMoreDataView.deleteItems(at: [IndexPath(item: 0, section: strongSelf.loadMoreFooterSection)])
            } else if show && !strongSelf.requestObject.hidesFooter {
                strongSelf.loadMoreDataView.reloadData()
            }
        }
    }

}
