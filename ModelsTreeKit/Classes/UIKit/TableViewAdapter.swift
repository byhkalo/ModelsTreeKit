//
//  TableViewAdapter.swift
//  SessionSwift
//
//  Created by aleksey on 18.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import UIKit

public class TableViewAdapter<ObjectType>: NSObject, UITableViewDataSource, UITableViewDelegate {
    typealias DataSourceType = ObjectsDataSource<ObjectType>
    weak var tableView: UITableView!
    
    private var nibs = [String: UINib]()
    
    public var nibNameForObjectMatching: (ObjectType -> String)!

    public let didSelectCellSignal = Signal<(cell: UITableViewCell?, object: ObjectType?)>()
    public let willDisplayCell = Signal<UITableViewCell>()
    public let didEndDisplayingCell = Signal<UITableViewCell>()

    private var dataSource: ObjectsDataSource<ObjectType>!
    private var instances = [String: UITableViewCell]()
    private var identifiersForIndexPaths = [NSIndexPath: String]()
    private var pool = AutodisposePool()
    
    public init(dataSource: ObjectsDataSource<ObjectType>, tableView: UITableView) {
        super.init()
        
        self.tableView = tableView
        tableView.dataSource = self
        tableView.delegate = self
        
        self.dataSource = dataSource
        
        dataSource.beginUpdatesSignal.subscribeNext { [weak self] in
            self?.tableView.beginUpdates()
        }.putInto(pool)
        
        dataSource.endUpdatesSignal.subscribeNext { [weak self] in
            self?.tableView.endUpdates()
        }.putInto(pool)
        
        dataSource.reloadDataSignal.subscribeNext { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            UIView.animateWithDuration(0.1, animations: {
                strongSelf.tableView.alpha = 0},
                completion: { completed in
                    strongSelf.tableView.reloadData()
                    UIView.animateWithDuration(0.2, animations: {
                        strongSelf.tableView.alpha = 1
                })
            })
        }.putInto(pool)
        
        dataSource.didChangeObjectSignal.subscribeNext { [weak self] object, changeType, fromIndexPath, toIndexPath in
            guard let strongSelf = self else {
                return
            }
            
            switch changeType {
            case .Insertion:
                if let toIndexPath = toIndexPath {
                    strongSelf.tableView.insertRowsAtIndexPaths([toIndexPath],
                            withRowAnimation: UITableViewRowAnimation.Fade)
                }
            case .Deletion:
                if let fromIndexPath = fromIndexPath {
                    strongSelf.tableView.deleteRowsAtIndexPaths([fromIndexPath],
                            withRowAnimation: .Fade)
                }
            case .Update:
                if let indexPath = toIndexPath {
                    strongSelf.tableView.reloadRowsAtIndexPaths([indexPath],
                            withRowAnimation: .Fade)
                }
            case .Move:
                if let fromIndexPath = fromIndexPath, let toIndexPath = toIndexPath {
                    strongSelf.tableView.moveRowAtIndexPath(fromIndexPath,
                            toIndexPath: toIndexPath)
                }
            }
        }.putInto(pool)
        
        dataSource.didChangeSectionSignal.subscribeNext { [weak self] changeType, fromIndex, toIndex in
            guard let strongSelf = self else {
                return
            }
            
            switch changeType {
            case .Insertion:
                if let toIndex = toIndex {
                    strongSelf.tableView.insertSections(NSIndexSet(index: toIndex),
                            withRowAnimation: .Fade)
                }
            case .Deletion:
                if let fromIndex = fromIndex {
                    strongSelf.tableView.deleteSections(NSIndexSet(index: fromIndex),
                            withRowAnimation: .Fade)
                }
            default:
                break
            }
        }.putInto(pool)
    }
    
    public func registerNibNamed(nibName: String) {
        let nib = UINib(nibName: nibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: nibName)
        nibs[nibName] = nib
        instances[nibName] = nib.instantiateWithOwner(self, options: nil).last as? UITableViewCell
    }

    //UITableViewDataSource

    @objc
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfObjectsInSection(section)
    }

    @objc
    public func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
                    
        let object = dataSource.objectAtIndexPath(indexPath)!;
        let nibName = nibNameForObjectMatching(object)
                    
        let identifier = nibNameForObjectMatching(object)
        var cell = tableView.dequeueReusableCellWithIdentifier(identifier)
        identifiersForIndexPaths[indexPath] = identifier

        if cell == nil {
            cell = (nibs[nibName]!.instantiateWithOwner(nil, options: nil).last as! UITableViewCell)
        }

        if var consumer = cell as? ObjectConsuming {
            consumer.object = dataSource.objectAtIndexPath(indexPath)
        }

        return cell!
    }

    @objc
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource.numberOfSections()
    }
    
    // UITableViewDelegate
    
    @objc
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let identifier = nibNameForObjectMatching(dataSource.objectAtIndexPath(indexPath)!)
        if let cell = instances[identifier] as? HeightCalculatingCell {
            return cell.heightFor(dataSource.objectAtIndexPath(indexPath), width: tableView.frame.size.width)
        }
        return UITableViewAutomaticDimension;
    }

    @objc
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        didSelectCellSignal.sendNext((cell: tableView.cellForRowAtIndexPath(indexPath),
                object: dataSource.objectAtIndexPath(indexPath)))
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    @objc
    public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        willDisplayCell.sendNext(cell)
    }
    
    public func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        didEndDisplayingCell.sendNext(cell)
    }
}