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
    
    lazy var requestObject: LoadMoreRequestObject<String> = {
        var _requestObject = LoadMoreRequestObject<String>()
        _requestObject.totalCount = 101
        _requestObject.limit = 50
        return _requestObject
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)


        requestObject.fetchSourceObjects = { [weak self] completion in
            var newNumbers = [Int]()
            for _ in 0..<self!.requestObject.limit {
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
                
                self?.requestObject.currentPage += 1
                
                delay(refreshing ? 0.3 : 0) {
                    completion(newNumbers.map { "sample \($0)" }, self!.requestObject.hasNext)
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
            return requestObject.sourceObjects.count
        case .footer:
            return (requestObject.hidesFooter ? 0 : 1)
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
            loadMore(reload: false)
        }
        
    }

}

extension ViewController {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        requestObject.isScrolling = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            requestObject.isScrolling = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        requestObject.isScrolling = false
    }
}

extension ViewController: LoadMoreProvider {
    
    var loadMoreDataView: UITableView {
        return tableView
    }
    
    var loadMoreFooterSection: Int {
        return 1
    }
    
    
    var loadMoreMainSection: Int {
        return 0
    }

}
