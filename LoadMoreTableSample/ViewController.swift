//
//  ViewController.swift
//  LoadMoreTableSample
//
//  Created by maru on 2017/12/16.
//
//

import UIKit


enum SectionType {
    case main
    case footer
}


func delay(_ delay: TimeInterval, block: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        block()
    }
}


class ViewController: UIViewController {
    
    private var count = 0

    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    let sectionTypes: [SectionType] = [.main, .footer]
    var hidesFooter = false
    var isRequesting = false
    
    var isScrolling = false {
        didSet {
            if !isScrolling && pendingProcess != nil {
                pendingProcess?()
                pendingProcess = nil
            }
        }
    }
    
    var pendingProcess: (() -> Void)?
    var sourceObjects = [Any]()
    
    var fetchSourceObjects: (_ completion: @escaping (_ sourceObjects: [Any], _ hasNext: Bool) -> ()) -> () = { _ in  }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)


        fetchSourceObjects = { [weak self] completion in
            var newNumbers = [Int]()
            for _ in 0..<50 {
                self?.count += 1
                newNumbers.append(self?.count ?? 0)
            }
            
            delay(1) { // Pretend to fetch data
                // Test retry button
//                let showRetryButton = newNumbers.filter { $0 % 20 == 0 }.count > 0
//                if showRetryButton {
//                    delay(0.1) {
//                        self?.showRetryButton()
//                    }
//                }
                
                let refreshing = self?.tableView.refreshControl?.isRefreshing == true
                if refreshing {
                    self?.tableView.refreshControl?.endRefreshing()
                }
                
                if self!.count > 200 {
                    delay(refreshing ? 0.3 : 0) {
                        completion(newNumbers.map { "sample \($0)" }, false)
                    }
                } else {
                    delay(refreshing ? 0.3 : 0) {
                        completion(newNumbers.map { "sample \($0)" }, true)
                    }
                }
                

            }
        }
        
        tableView.tableFooterView = UIView()
        
        tableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: "LoadingCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
    }
    
    
    func clear() {
        count = 0
        refreshData(immediately: true)
    }
    
    func refresh() {
        count = 0
        refreshData(immediately: false)
    }

    
    func refreshData(immediately: Bool) {
        sourceObjects.removeAll()
        
        if immediately {
            isScrolling = false
        }
        
        DispatchQueue.main.async {
            if immediately {
                self.tableView.reloadData()
                self.updateFooter(show: true)
            } else {
                self.loadMore(reload: true)
            }
        }
    }
    
    func updateTable(reload: Bool, hasNext: Bool) {
        DispatchQueue.main.async {
//            UIView.setAnimationsEnabled(false)
            
            if let mainSection = self.sectionTypes.index(of: .main) {
                let newDataCount = self.sourceObjects.count
                let currentDataCount = self.tableView.numberOfRows(inSection: mainSection)
                if currentDataCount < newDataCount {
                    self.tableView.insertRows(at: Array(currentDataCount..<newDataCount).map { IndexPath(row: $0, section: mainSection) }, with: .none)
                    
                } else {
                    self.tableView.deleteRows(at: Array(newDataCount..<currentDataCount).map { IndexPath(row: $0, section: mainSection) }, with: .none)
                }
                
                if reload {
                    self.tableView.reloadRows(at: Array(0..<newDataCount).map { IndexPath(row: $0, section: mainSection) }, with: .none)
                }
            }
            
//            UIView.setAnimationsEnabled(true)
            
            if !hasNext {
                self.updateFooter(show: false)
            } else {
                self.updateFooter(show: true)
            }
        }
    }
    
    func updateFooter(show: Bool) {
        guard pendingProcess == nil else { return }
        
        guard let footerSection = sectionTypes.index(of: .footer) else { return }
        
        DispatchQueue.main.async {
            if show && self.hidesFooter {
                self.hidesFooter = false
                self.tableView.insertRows(at: [IndexPath(row: 0, section: footerSection)], with: .none)
            } else if !show && !self.hidesFooter {
                self.hidesFooter = true
                self.tableView.deleteRows(at: [IndexPath(row: 0, section: footerSection)], with: .none)
            } else if show && !self.hidesFooter {
                self.tableView.reloadData()
            }
        }
    }
    
    func loadMore(reload: Bool = false) {
        guard !isRequesting else { return }
        isRequesting = true
        
        let oldDataCount = sourceObjects.count
        
        DispatchQueue.global().async {
            self.fetchSourceObjects() { [weak self] sourceObjects, hasNext in
                guard let strongSelf = self else { return }
                
                if oldDataCount == strongSelf.sourceObjects.count {
                    strongSelf.sourceObjects += sourceObjects
                }
                
                if strongSelf.isScrolling == true {
                    if strongSelf.pendingProcess == nil {
                        strongSelf.pendingProcess = {
                            strongSelf.updateTable(reload: reload, hasNext: hasNext)
                        }
                    }
                } else {
                    strongSelf.updateTable(reload: reload, hasNext: hasNext)
                }
                
                strongSelf.isRequesting = false
            }
        }
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sectionTypes[section]
        switch sectionType {
        case .main:
            return sourceObjects.count
        case .footer:
            return (hidesFooter ? 0 : 1)
        }
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let sectionType = sectionTypes[indexPath.section]
        switch sectionType {
        case .main:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = "\(indexPath.row)"
            return cell
        case .footer:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
            cell.backgroundColor = .clear
            
            cell.separatorInset =  UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0)
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if sectionTypes[indexPath.section] == .footer {
            loadMore()
        }
        
    }

}

extension ViewController {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }
}
