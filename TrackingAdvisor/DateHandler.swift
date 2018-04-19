//
//  DateHandler.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/7/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation

class DateHandler {
    class func dateToDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    class func dateToHourString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    class func dateToLetterAndPeriod(from date: Date) -> String {
        var str = Formatter.customDateLetter.string(from: date)
        str += " at " + Formatter.timePeriod.string(from: date)
        return str
    }
    
    class func dateToDayLetterString(from date: Date) -> String {
        return Formatter.customFullDateLetter.string(from: date)
    }
    
    class func dateToTimePeriodString(from date: Date) -> String {
        return Formatter.timePeriod.string(from: date)
    }
    
    class func dateFromDayString(from day: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: day)
    }
}

extension Formatter {
    static let customDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    static let customDateLetter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    static let customFullDateLetter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ccc d MMMM yyyy"
        return formatter
    }()
    static let fullDateLetter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "cccc d MMMM yyyy"
        return formatter
    }()
    static let time:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    static let timePeriod:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    static let weekdayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "cccc"
        return formatter
    }()
    static let month: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        return formatter
    }()
}

extension Calendar {
    static let gregorian = Calendar(identifier: .gregorian)
}

extension Date {
    var customDate: String {
        return Formatter.customDate.string(from: self)
    }
    var customDateLetter: String {
        return Formatter.customDateLetter.string(from: self)
    }
    var customTimePeriod: String {
        return Formatter.timePeriod.string(from: self)
    }
    var customTime: String {
        return Formatter.time.string(from: self)
    }
    var weekdayName: String {
        return Formatter.weekdayName.string(from: self)
    }
    var monthName: String {
        return Formatter.month.string(from: self)
    }
    var dayOfWeek: Int {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: self)
        return calendar.component(.weekday, from: date)
    }
    var dayOfWeekName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(for: self) ?? ""
    }
    // the same for your local time
    var localTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZZ"
        return formatter.string(for: self) ?? ""
    }
    // or GMT time
    var GMTTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS ZZZ"
        return formatter.string(for: self) ?? ""
    }
    
    var startOfDay: Date {
        let calendar = Calendar.current
        let unitFlags = Set<Calendar.Component>([.year, .month, .day])
        let components = calendar.dateComponents(unitFlags, from: self)
        return calendar.date(from: components)!
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        let date = Calendar.current.date(byAdding: components, to: self.startOfDay)
        return (date?.addingTimeInterval(-1))!
    }
    
    public func earlier(_ date:Date) -> Date{
        return (self.timeIntervalSince1970 <= date.timeIntervalSince1970) ? self : date
    }
    
    var startOfWeek: Date? {
        return Calendar.gregorian.date(from: Calendar.gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
    }
    
    public func timeAgo(since date:Date, numericDates: Bool = false, numericTimes: Bool = false) -> String {
        let calendar = Calendar.current
        let unitFlags = Set<Calendar.Component>([.second,.minute,.hour,.day,.weekOfYear,.month,.year])
        let earliest = self.earlier(date)
        let latest = (earliest == self) ? date : self
        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        
        if (components.year! >= 2) {
            return "\(components.year!) years ago"
        }
        else if (components.year! >= 1) {
            
            if (numericDates) {
                return "1 year ago"
            }
            
            return "Last year"
        }
        else if (components.month! >= 2) {
            return "\(components.month!) months ago"
        }
        else if (components.month! >= 1) {
            
            if (numericDates) {
                return "1 month ago"
            }
            
            return "Last month"
        }
        else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!) weeks ago"
        }
        else if (components.weekOfYear! >= 1) {
            
            if (numericDates) {
                return "1 week ago"
            }
            
            
            return "Last week"
        }
        else if (components.day! >= 2) {
            return "\(components.day!) days ago"
        }
        else if (components.day! >= 1) {
            if (numericDates) {
                return "1 day ago"
            }
            
            return "Yesterday"
        }
        else if (components.hour! >= 2) {
            return "\(components.hour!) hours ago"
        }
        else if (components.hour! >= 1) {
            
            if (numericTimes) {
                return "1 hour ago"
            }
            
            return "An hour ago"
        }
        else if (components.minute! >= 2) {
            return "\(components.minute!) minutes ago"
        }
        else if (components.minute! >= 1) {
            
            if (numericTimes) {
                return "1 minute ago"
            }
            
            return "A minute ago"
        }
        else if (components.second! >= 2) {
            return "\(components.second!) seconds ago"
        }
        else {
            
            if (numericTimes) {
                return "1 second ago"
            }
            
            return "Just now"
        }
    }
    
    public func dayAgo(since date:Date, numericDates: Bool = false, numericTimes: Bool = false, spellOut: Bool = false) -> String {
        let calendar = Calendar.current
        let unitFlags = Set<Calendar.Component>([.second,.minute,.hour,.day,.weekOfYear,.month,.year])
        let earliest = self.earlier(date)
        let latest = (earliest == self) ? date : self
        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        
        if (components.year! >= 2) {
            if (spellOut) {
                return "\(components.year!.spellOut()) years ago"
            }
            return "\(components.year!) years ago"
        }
        else if (components.year! >= 1) {
            
            if (numericDates) {
                if (spellOut) {
                    return "\(Int(1).spellOut()) year ago"
                }
                return "1 year ago"
            }
            
            return "Last year"
        }
        else if (components.month! >= 2) {
            if (spellOut) {
                return "\(components.month!.spellOut()) years ago"
            }
            return "\(components.month!) months ago"
        }
        else if (components.month! >= 1) {
            
            if (numericDates) {
                if (spellOut) {
                    return "\(Int(1).spellOut()) month ago"
                }
                return "1 month ago"
            }
            
            return "Last month"
        }
        else if (components.weekOfYear! >= 2) {
            if (spellOut) {
                return "\(components.weekOfYear!.spellOut()) weeks ago"
            }
            return "\(components.weekOfYear!) weeks ago"
        }
        else if (components.weekOfYear! >= 1) {
            
            if (numericDates) {
                if (spellOut) {
                    return "\(Int(1).spellOut()) week ago"
                }
                return "1 week ago"
            }
            
            return "Last week"
        }
        else if (components.day! >= 2) {
            if (spellOut) {
                return "\(components.day!.spellOut()) days ago"
            }
            return "\(components.day!) days ago"
        }
        else if (components.day! >= 1) {
            if (numericDates) {
                if (spellOut) {
                    return "\(Int(1).spellOut()) day ago"
                }
                return "1 day ago"
            }
            
            return "Yesterday"
        }
        else {
            return "Today"
        }
    }
    
    public func numberOfDays(to date: Date?) -> Int? {
        guard let date = date else { return nil }
        
        let calendar = Calendar.current
        let earliest = self.earlier(date)
        let latest = (earliest == self) ? date : self
        let components = calendar.dateComponents([.day], from: earliest, to: latest)
        
        return components.day
    }
    
}

extension String {
    var customDate: Date? {
        return Formatter.customDate.date(from: self)
    }
}

extension TimeInterval {
    func timeIntervalToString() -> String {
        let ti = Int(self)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        if hours != 0 {
            let hourStr = hours > 1 ? "hours" : "hour"
            if 0 ... 10 ~= minutes {
                return "just over \(hours) \(hourStr)"
            } else if 10 ... 50 ~= minutes {
                return "\(hours) \(hourStr) and \(minutes) minutes"
            } else {
                return "almost \(hours+1) \(hourStr)"
            }
        } else if minutes != 0 {
            if 0 ... 10 ~= minutes {
                return "a few minutes"
            } else if 10 ... 50 ~= minutes {
                return "\(minutes) minutes"
            } else {
                return "almost one hour"
            }
        } else if seconds != 0 {
            if 0 ... 30 ~= seconds {
                return "a few seconds"
            } else {
                return "almost a minute"
            }
        }
        return ""
    }
}


