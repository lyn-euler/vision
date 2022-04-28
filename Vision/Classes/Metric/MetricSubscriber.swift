//
//  MetricSubscriber.swift
//  CoRe
//
//  Created by ello on 2022/4/21.
//

import Foundation
import MetricKit

public typealias MetricSubscriberReport = (_ paylod : [AnyHashable : Any]) -> Void

open class MetricSubscriber: NSObject {
    private static let shared = MetricSubscriber()
    private override init() {}
    private var report: MetricSubscriberReport?
    
    public static func subscribe(_ report: @escaping MetricSubscriberReport) {
        assert(MetricSubscriber.shared.report == nil)
        MetricSubscriber.shared.report = report
        MXMetricManager.shared.add(MetricSubscriber.shared)
    }
    
    public static func unSubscribe() {
        MetricSubscriber.shared.report = nil
        MXMetricManager.shared.remove(MetricSubscriber.shared)
    }
    
}


extension MetricSubscriber: MXMetricManagerSubscriber {
    public func didReceive(_ payloads: [MXMetricPayload]) {
        payloads.forEach { p in
            report?(p.dictionaryRepresentation())
//            print(p.dictionaryRepresentation())
        }
//        Logger.debug("\(payloads)")
    }
    
    @available(iOS 14.0, *)
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        payloads.forEach { p in
            report?(p.dictionaryRepresentation())
        }
    }
}
