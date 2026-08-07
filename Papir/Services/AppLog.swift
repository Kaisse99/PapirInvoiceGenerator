//
//  AppLog.swift
//  The app's loggers, one per concern, so when she says it did not save there
//  is something to look at in Console instead of a shrug. os.Logger costs
//  nothing when nobody is looking and redacts interpolated values by default,
//  so nothing about a customer leaks into a sysdiagnose unless marked public
//  on purpose; only error text ever is.
//  Used by: PapirApp, the view models, DataExport call sites.
//

import os

enum AppLog {
    static let store = Logger(subsystem: "com.kaissenberg.Papir", category: "store")
    static let data = Logger(subsystem: "com.kaissenberg.Papir", category: "data")
    static let pdf = Logger(subsystem: "com.kaissenberg.Papir", category: "pdf")
    static let export = Logger(subsystem: "com.kaissenberg.Papir", category: "export")
}
