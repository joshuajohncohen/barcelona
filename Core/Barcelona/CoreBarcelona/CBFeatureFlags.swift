//
//  CBFeatureFlags.swift
//  Barcelona
//
//  Created by Eric Rabil on 1/11/22.
//

import Foundation
import FeatureFlags

#if DEBUG
private let isDebugBuild = true
#else
private let isDebugBuild = false
#endif

// to enable something off by default, --enable-
// to disable, --disable-
public class _CBFeatureFlags: FlagProvider {
    public let suiteName = "com.ericrabil.barcelona"
    
    @FeatureFlag("matrix-audio", defaultValue: false)
    public var permitAudioOverMautrix: Bool
    
    @FeatureFlag("internal-diagnostics", defaultValue: isDebugBuild)
    public var internalDiagnostics: Bool
    
    @FeatureFlag("xcode", domain: .debugging, defaultValue: false)
    public var runningFromXcode: Bool
    
    @FeatureFlag("any-country", defaultValue: false)
    public var ignoresSameCountryCodeAssertion: Bool
    
    @FeatureFlag("scratchbox", domain: .debugging, defaultValue: false)
    public var scratchbox: Bool
    
    @FeatureFlag("exit-after-scratchbox", domain: .debugging, defaultValue: true)
    public var exitAfterScratchbox: Bool
    
    @FeatureFlag("prewarm-item-rules", defaultValue: true)
    public var prewarmItemRules: Bool
    
    @FeatureFlag("contact-fuzz-enumerator", defaultValue: true)
    public var contactFuzzEnumerator: Bool
    
    @FeatureFlag("sms-read-buffer", defaultValue: true)
    public var useSMSReadBuffer: Bool
    
    @FeatureFlag("drop-spam-messages", defaultValue: true)
    public var dropSpamMessages: Bool
    
    @FeatureFlag("log-sensitive-payloads", defaultValue: isDebugBuild)
    public var logSensitivePayloads: Bool
}

extension String {
    var splitByCamel: [String] {
        unicodeScalars.reduce(into: [""]) { accumulator, character in
            if CharacterSet.uppercaseLetters.contains(character) {
                accumulator.append(String(character).lowercased())
            } else {
                accumulator[accumulator.index(before: accumulator.endIndex)].append(String(character))
            }
        }
    }
    
    var camelToHyphen: String {
        splitByCamel.joined(separator: "-")
    }
}

@dynamicMemberLookup
public class _CBLoggingFlags: FlagProvider {
    private var cache: [String: FeatureFlag] = [:]

    public let suiteName = "com.ericrabil.barcelona.logging"

    private func flag(dynamicMember: String) -> FeatureFlag {
        if _slowPath(!cache.keys.contains(dynamicMember)) {
            let flag = FeatureFlag(dynamicMember.camelToHyphen, domain: .feature, defaultValue: false)
            cache[dynamicMember] = flag
            return flag
        }
        return cache[dynamicMember]!
    }

    public subscript(dynamicMember dynamicMember: String) -> Bool {
        flag(dynamicMember: dynamicMember).value(inSuite: suiteName)
    }
}

public let CBFeatureFlags = _CBFeatureFlags()
public let CBLoggingFlags = _CBLoggingFlags()

@_transparent internal func ifInternal(_ block: () -> ()) {
    if CBFeatureFlags.internalDiagnostics {
        block()
    }
}

@_transparent internal func ifDebugBuild(_ block: () -> ()) {
    #if DEBUG
    block()
    #endif
}

@_transparent internal func ifReleaseBuild(_ block: () -> ()) {
    #if !DEBUG
    block()
    #endif
}