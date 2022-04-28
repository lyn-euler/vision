//
//  ProcessInfo.swift
//  CoRe
//
//  Created by ello on 2022/4/24.
//

import Foundation

public struct APMProcessInfo {
    public static var shared = APMProcessInfo()
    private init() {}
    public lazy var isActivePrewarm: Bool = {
        guard let isActivePrewarm = ProcessInfo.processInfo.environment["ActivePrewarm"],
              let data = isActivePrewarm.data(using: .utf8) else {
            return false
        }
        let decoder = JSONDecoder()
        guard let result = try? decoder.decode(Bool.self, from: data) else {
            return false
        }
        return result
    }()
}
