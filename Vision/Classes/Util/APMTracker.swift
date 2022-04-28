//
//  TickTime.swift
//  CoRe
//
//  Created by ello on 2022/4/20.
//

import Foundation
//#if os(macOS) || os(iOS)
import Darwin.C.time


public struct APMTracker {
    
    public static func duration(name: String = "", _ block: () -> Void) {
        let s = CFAbsoluteTimeGetCurrent()
        block()
        let e = CFAbsoluteTimeGetCurrent()
//        let duration = "[\(name)]耗时:\((e - s) * 1000)ms"
        print("[\(name)]耗时:\((e - s) * 1000)ms")
    }
    
    public static var threadCPUTime: Double {
        let tp = UnsafeMutablePointer<timespec>.allocate(capacity: MemoryLayout<timespec>.stride)
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, tp)
        defer {
            tp.deallocate()
        }
        return Double(tp.pointee.tv_sec) + Double(tp.pointee.tv_nsec) / 1e9
    }
    
    public static var machAbsoluteTime: Double {
        return CFAbsoluteTimeGetCurrent()
    }
}
