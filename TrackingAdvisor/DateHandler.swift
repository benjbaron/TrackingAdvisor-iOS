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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        var str = formatter.string(from: date)
        formatter.dateFormat = "h:mm a"
        str += " at " + formatter.string(from: date)
        return str
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


}

extension String {
    var customDate: Date? {
        return Formatter.customDate.date(from: self)
    }
}
