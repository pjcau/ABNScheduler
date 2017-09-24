//
//  ABNQueue.swift
//  ABNSDemo
//
//  Created by Pierre jonny cau on 24/09/2017.
//  Copyright © 2017 Ahmed Abdul Badie. All rights reserved.
//

import Foundation


///- author: Ahmed Abdul Badie
open class ABNQueue : NSObject {
    fileprivate var notifQueue = [ABNotification]()
    static let queue = ABNQueue()
    let ArchiveURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("notifications.abnqueue")
    
    override init() {
        super.init()
        if let notificationQueue = self.load() {
            notifQueue = notificationQueue
        }
    }
    
    ///- paramater notification ABNotification to push.
    func push(_ notification: ABNotification) {
        notifQueue.insert(notification, at: findInsertionPoint(notification))
    }
    
    /// Finds the position at which the new ABNotification is inserted in the queue.
    /// - parameter notification: ABNotification to insert.
    /// - returns: Index to insert the ABNotification at.
    /// - seealso: [swift-algorithm-club](https://github.com/hollance/swift-algorithm-club/tree/master/Ordered%20Array)
    func findInsertionPoint(_ notification: ABNotification) -> Int {
        let range = 0..<notifQueue.count
        var rangeLowerBound = range.lowerBound
        var rangeUpperBound = range.upperBound
        
        while rangeLowerBound < rangeUpperBound {
            let midIndex = rangeLowerBound + (rangeUpperBound - rangeLowerBound) / 2
            if notifQueue[midIndex] == notification {
                return midIndex
            } else if notifQueue[midIndex] < notification {
                rangeLowerBound = midIndex + 1
            } else {
                rangeUpperBound = midIndex
            }
        }
        return rangeLowerBound
    }
    
    ///Removes and returns the head of the queue.
    ///- returns: The head of the queue.
    func pop() -> ABNotification {
        return notifQueue.removeFirst()
    }
    
    ///- returns: The head of the queue.
    func peek() -> ABNotification? {
        return notifQueue.last
    }
    
    ///Clears the queue.
    func clear() {
        notifQueue.removeAll()
    }
    
    ///Called when an ABNotification is cancelled.
    ///- parameter index: Index of ABNotification to remove.
    func removeAtIndex(_ index: Int) {
        notifQueue.remove(at: index)
    }
    
    ///- returns: Count of ABNotification in the queue.
    func count() -> Int {
        return notifQueue.count
    }
    
    ///- returns: The notifications queue.
    func notificationsQueue() -> [ABNotification] {
        let queue = notifQueue
        return queue
    }
    
    ///- parameter identifier: Identifier of the notification to return.
    ///- returns: ABNotification if found, nil otherwise.
    func notificationWithIdentifier(_ identifier: String) -> ABNotification? {
        for note in notifQueue {
            if note.identifier == identifier {
                return note
            }
        }
        return nil
    }
    
    // MARK: NSCoding
    
    ///Save queue on disk.
    ///- returns: The success of the saving operation.
    func save() -> Bool {
        return NSKeyedArchiver.archiveRootObject(self.notifQueue, toFile: ArchiveURL.path)
    }
    
    ///Load queue from disk.
    ///Called first when instantiating the ABNQueue singleton.
    ///You do not need to manually call this method and therefore do not declare it as public.
    func load() -> [ABNotification]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: ArchiveURL.path) as? [ABNotification]
    }
    
}
