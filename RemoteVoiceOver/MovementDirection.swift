//
//  MovementDirection.swift
//  TestVoiceOver
//
//  Created by Vincent Neo on 25/7/24.
//

import Cocoa

enum MovementDirection: String {
    case up
    case down
    case left
    case right
    
    var keyCode: CGKeyCode {
        switch self {
        case .up:
            return .kVK_UpArrow
        case .down:
            return .kVK_DownArrow
        case .left:
            return .kVK_LeftArrow
        case .right:
            return .kVK_RightArrow
        }
    }
}
