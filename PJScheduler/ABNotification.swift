//
//  ABNotification.swift
//  ABNSDemo
//
//  Created by Pierre jonny cau on 24/09/2017.
//  Copyright © 2017 Ahmed Abdul Badie. All rights reserved.
//

import Foundation
import UIKit



///- author: Ahmed Abdul Badie
enum Repeats: String {
    case None, Hourly, Daily, Weekly, Monthly, Yearly
}

///A wrapper class around UILocalNotification.
///- author: Ahmed Abdul Badie
open class ABNotification : NSObject, NSCoding, Comparable {
    var localNotification: UILocalNotification
    var alertBody: String
    var alertAction: String?
    var soundName: String?
    var repeatInterval = Repeats.None
    var userInfo: Dictionary<String, AnyObject>
    fileprivate(set) var identifier: String
    fileprivate var scheduled = false
    var fireDate: Date? {
        return localNotification.fireDate
    }
    
    init(alertBody: String) {
        self.alertBody = alertBody
        self.localNotification = UILocalNotification()
        self.identifier = UUID().uuidString
        self.userInfo = Dictionary<String, AnyObject>()
        super.init()
    }
    
    init(alertBody: String, identifier: String) {
        self.alertBody = alertBody
        self.localNotification = UILocalNotification()
        self.identifier = identifier
        self.userInfo = Dictionary<String, AnyObject>()
        super.init()
    }
    
    ///Used to instantiate an ABNotification when loaded from disk.
    fileprivate init(notification: UILocalNotification, alertBody: String, alertAction: String?, soundName: String?, identifier: String, repeats: Repeats, userInfo: Dictionary<String, AnyObject>, scheduled: Bool) {
        self.alertBody = alertBody
        self.alertAction = alertAction
        self.soundName = soundName;
        self.localNotification = notification
        self.identifier = identifier
        self.userInfo = userInfo
        self.repeatInterval = repeats
        self.scheduled = scheduled
        super.init()
    }
    
    ///Schedules the notification.
    ///> Checks to see if there is enough room for the notification to be scheduled. Otherwise, the notification is queued.
    ///- parameter fireDate: The date in which the notification will be fired at.
    ///- returns: The identifier of the notification. Use this identifier to retrieve the notification using `ABNQueue.notificationWithIdentifier` and `ABNScheduler.notificationWithIdentifier` methods.
    func schedule(fireDate date: Date) -> String? {
        if self.scheduled {
            return nil
        } else {
            self.localNotification = UILocalNotification()
            self.localNotification.alertBody = self.alertBody
            self.localNotification.alertAction = self.alertAction
            self.localNotification.fireDate = date.removeSeconds()
            self.localNotification.soundName = (self.soundName == nil) ? UILocalNotificationDefaultSoundName : self.soundName;
            self.userInfo[ABNScheduler.identifierKey] = self.identifier as AnyObject?
            self.localNotification.userInfo = self.userInfo
            
            self.soundName = self.localNotification.soundName
            
            if repeatInterval != .None {
                switch repeatInterval {
                case .Hourly: self.localNotification.repeatInterval = NSCalendar.Unit.hour
                case .Daily: self.localNotification.repeatInterval = NSCalendar.Unit.day
                case .Weekly: self.localNotification.repeatInterval = NSCalendar.Unit.weekOfYear
                case .Monthly: self.localNotification.repeatInterval = NSCalendar.Unit.month
                case .Yearly: self.localNotification.repeatInterval = NSCalendar.Unit.year
                default: break
                }
            }
            let count = ABNScheduler.scheduledCount()
            if count >= min(ABNScheduler.maximumScheduledNotifications, MAX_ALLOWED_NOTIFICATIONS) {
                if let farthestNotification = ABNScheduler.farthestLocalNotification() {
                    if farthestNotification > self {
                        farthestNotification.cancel()
                        ABNQueue.queue.push(farthestNotification)
                        self.scheduled = true
                        UIApplication.shared.scheduleLocalNotification(self.localNotification)
                    } else {
                        ABNQueue.queue.push(self)
                    }
                }
                return self.identifier
            }
            self.scheduled = true
            UIApplication.shared.scheduleLocalNotification(self.localNotification)
            return self.identifier
        }
    }
    
    ///Reschedules the notification.
    ///- parameter fireDate: The date in which the notification will be fired at.
    func reschedule(fireDate date: Date) {
        cancel()
        let _ = schedule(fireDate: date)
    }
    
    ///Cancels the notification if scheduled or queued.
    func cancel() {
        UIApplication.shared.cancelLocalNotification(self.localNotification)
        let queue = ABNQueue.queue.notificationsQueue()
        var i = 0
        for note in queue {
            if self.identifier == note.identifier {
                ABNQueue.queue.removeAtIndex(i)
                break
            }
            i += 1
        }
        scheduled = false
    }
    
    ///Snoozes the notification for a number of minutes.
    ///- parameter minutes: Minutes to snooze the notification for.
    func snoozeForMinutes(_ minutes: Int) {
        reschedule(fireDate: self.localNotification.fireDate!.nextMinutes(minutes))
    }
    
    ///Snoozes the notification for a number of hours.
    ///- parameter minutes: Hours to snooze the notification for.
    func snoozeForHours(_ hours: Int) {
        reschedule(fireDate: self.localNotification.fireDate!.nextHours(hours))
    }
    
    ///Snoozes the notification for a number of days.
    ///- parameter minutes: Days to snooze the notification for.
    func snoozeForDays(_ days: Int) {
        reschedule(fireDate: self.localNotification.fireDate!.nextDays(days))
    }
    
    ///- returns: The state of the notification.
    func isScheduled() -> Bool {
        return self.scheduled
    }
    
    ///Used by ABNotificationX classes to convert NSCalendarUnit enum to Repeats enum.
    ///- parameter calendarUnit: NSCalendarUnit to convert.
    ///- returns: Repeats type that is equivalent to the passed NSCalendarUnit.
    class func calendarUnitToRepeats(calendarUnit cUnit: NSCalendar.Unit) -> Repeats {
        switch cUnit {
        case NSCalendar.Unit.hour: return .Hourly
        case NSCalendar.Unit.day: return .Daily
        case NSCalendar.Unit.weekOfYear: return .Weekly
        case NSCalendar.Unit.month: return .Monthly
        case NSCalendar.Unit.year: return .Yearly
        default: return Repeats.None
        }
    }
    
    ///Instantiates an ABNotification from a UILocalNotification.
    ///- parameter localNotification: The UILocalNotification to instantiate an ABNotification from.
    ///- returns: The instantiated ABNotification from the UILocalNotification.
    class func notificationWithUILocalNotification(_ localNotification: UILocalNotification) -> ABNotification {
        let alertBody = localNotification.alertBody!
        let alertAction = localNotification.alertAction
        let soundName = localNotification.soundName
        let identifier = localNotification.userInfo![ABNScheduler.identifierKey] as! String
        let repeats = self.calendarUnitToRepeats(calendarUnit: localNotification.repeatInterval)
        let userInfo = localNotification.userInfo!
        
        return ABNotification(notification: localNotification, alertBody: alertBody, alertAction: alertAction, soundName: soundName, identifier: identifier, repeats: repeats, userInfo: userInfo as! Dictionary<String, AnyObject>, scheduled: true)
    }
    
    // MARK: NSCoding
    
    @objc convenience public required init?(coder aDecoder: NSCoder) {
        guard let localNotification = aDecoder.decodeObject(forKey: "ABNNotification") as? UILocalNotification  else {
            return nil
        }
        
        guard let alertBody =  aDecoder.decodeObject(forKey: "ABNAlertBody") as? String else {
            return nil
        }
        
        guard let identifier = aDecoder.decodeObject(forKey: "ABNIdentifier") as? String else {
            return nil
        }
        
        guard let userInfo = aDecoder.decodeObject(forKey: "ABNUserInfo") as? Dictionary<String, AnyObject> else {
            return nil
        }
        
        guard let repeats = aDecoder.decodeObject(forKey: "ABNRepeats") as? String else {
            return nil
        }
        
        guard let soundName = aDecoder.decodeObject(forKey: "ABNSoundName") as? String else {
            return nil
        }
        
        let alertAction = aDecoder.decodeObject(forKey: "ABNAlertAction") as? String
        
        self.init(notification: localNotification, alertBody: alertBody, alertAction: alertAction, soundName: soundName, identifier: identifier, repeats: Repeats(rawValue: repeats)!, userInfo: userInfo, scheduled: false)
    }
    
    @objc open func encode(with aCoder: NSCoder) {
        aCoder.encode(localNotification, forKey: "ABNNotification")
        aCoder.encode(alertBody, forKey: "ABNAlertBody")
        aCoder.encode(alertAction, forKey: "ABNAlertAction")
        aCoder.encode(soundName, forKey: "ABNSoundName")
        aCoder.encode(identifier, forKey: "ABNIdentifier")
        aCoder.encode(repeatInterval.rawValue, forKey: "ABNRepeats")
        aCoder.encode(userInfo, forKey: "ABNUserInfo")
    }
    
}



public func <(lhs: ABNotification, rhs: ABNotification) -> Bool {
    return lhs.localNotification.fireDate?.compare(rhs.localNotification.fireDate!) == ComparisonResult.orderedAscending
}

public func ==(lhs: ABNotification, rhs: ABNotification) -> Bool {
    return lhs.identifier == rhs.identifier
}

