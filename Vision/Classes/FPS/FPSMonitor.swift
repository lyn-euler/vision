//
//  FPSMonitor.swift
//  CoRe
//
//  Created by ello on 2022/4/15.
//

import UIKit

public typealias FPSObserverClosure = (_ fsp: Double) -> Void

open class FPSMonitor {
    public static let shared = FPSMonitor()

    private let lock = NSLock()

    private var _displayLink: CADisplayLink? {
        willSet {
            _displayLink?.invalidate()
        }
    }

    private var displayLink: CADisplayLink {
        if _displayLink == nil {
            _displayLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        }
        return _displayLink!
    }

    private var lastTickTime: TimeInterval
    private var preIsMonitoring = false
    private init() {
        lastTickTime = 0

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [unowned self] _ in
            if preIsMonitoring {
                start()
            }
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [unowned self] _ in
            preIsMonitoring = isMonitoring
            stop()
        }
    }

    deinit {
        _displayLink?.invalidate()
    }

    public var didFPSUpdate: FPSObserverClosure?
    private var isMonitoring = false
    public func start() {
        lock.lock()
        defer {
            lock.unlock()
        }
        if isMonitoring {
            return
        }
        isMonitoring = true
        displayLink.add(to: RunLoop.main, forMode: .common)
    }

    public func stop() {
//        _displayLink?.invalidate()
        lock.lock()
        defer {
            lock.unlock()
        }
        guard isMonitoring else {
            return
        }
        isMonitoring = false
        _displayLink = nil
    }

    private var fps: Double = 0 {
        didSet {
            guard let didFPSUpdate = didFPSUpdate else {
                return
            }
            didFPSUpdate(fps)
        }
    }

    private var tickCount: Int = 0
    @objc private func tick(_ displayLink: CADisplayLink) {
        print("tick")
        if lastTickTime < Double.ulpOfOne {
            lastTickTime = displayLink.timestamp
            return
        }
        tickCount += 1

        let duration = displayLink.timestamp - lastTickTime

        guard duration > 1 else {
            return
        }

        defer {
            tickCount = 0
            lastTickTime = displayLink.timestamp
        }
        fps = (Double(tickCount) / duration).rounded()
    }
}
