//
//  MarketsTableViewController.swift
//  Cryptomarket
//
//  Created by Alex on 05.01.18.
//  Copyright © 2018 Alexander Dobrynin. All rights reserved.
//

import UIKit

class MarketsTableViewController: UITableViewController {
    
    private struct Storyboard {
        static let SegueIdentifier = "ShowMarketSummarySegue"
    }
    
    // MARK: - Model
    
    var markets: [(key: String, value: [Market])] = [] {
        didSet { tableView.reloadData() }
    }
    
    // MARK: - Private Properties
    
    private let service = MarketService.default()

    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(
            UINib(nibName: MarketTableViewCell.Identifier, bundle: nil),
            forCellReuseIdentifier: MarketTableViewCell.Identifier
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        service.markets { result in
            switch result {
            case .success(let markets):
                self.markets = markets
                    .filter { $0.active }
                    .groupBy { $0.baseCurrency } // ["USDT": [BTC, XRP], "BTC": [ENG]]
                    .sorted { $0.key > $1.key } // [("USDT", [BTC, XRP]), ("BTC", [ENG])]
            case .failure(let error):
                print(error.localizedDescription) // FIXME: present error with alter view controller
            }

        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return markets.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return markets[section].value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MarketTableViewCell.Identifier, for: indexPath) as! MarketTableViewCell
        let market = markets[indexPath.section].value[indexPath.row]
        
        cell.configure(withImageUrl: market.logoUrl, andText: "\(market.currencyLong) (\(market.currency))")
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return markets[section].key
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(
            withIdentifier: Storyboard.SegueIdentifier,
            sender: markets[indexPath.section].value[indexPath.row]
        )
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case Storyboard.SegueIdentifier:
            let dest = segue.destination as! MarketSummaryTableViewController
            let market = sender as! Market
            
            dest.market = market
        default: break
        }
    }
}
