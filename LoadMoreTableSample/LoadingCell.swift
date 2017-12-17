
//
//  LoadingCell.swift
//  LoadMoreTableSample
//
//  Created by maru on 2017/12/16.
//
//

import UIKit

class LoadingCell: UITableViewCell {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        indicator.startAnimating()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
