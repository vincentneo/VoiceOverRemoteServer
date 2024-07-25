//
//  VoiceOverListener.swift
//  TestVoiceOver
//
//  Created by Vincent Neo on 25/7/24.
//

import SwiftUI
import MacroExpress

class VoiceOverListener: ObservableObject {
    @Published var isVoiceOverEnabled: Bool
    var voiceOverTask: Task<Void, Never>?
    
    @MainActor var latestPhrase: String?
    
    private var voiceOverObservation: NSKeyValueObservation?
    
    let app = express()

    init() {
        self.isVoiceOverEnabled = NSWorkspace.shared.isVoiceOverEnabled
        self.voiceOverStatusDidChange()
        voiceOverObservation = NSWorkspace.shared.observe(\.isVoiceOverEnabled) { [weak self] _, _ in
            DispatchQueue.main.async { [weak self] in
                self?.isVoiceOverEnabled = NSWorkspace.shared.isVoiceOverEnabled
                self?.voiceOverStatusDidChange()
            }
        }
        

        app.use(logger("dev"))
        app.use(bodyParser.urlencoded())
        app.use(cookieParser())
        app.use(session())

        app.get("/phrase") { _, res, _ in
            Task {
                if let latestPhrase = await self.latestPhrase {
                    res.send(latestPhrase)
                }
                else {
                    res.sendStatus(404)
                }
            }
        }
        
        app.get("/move/:direction") { req, res, _ in
            let parameters = req.params
            guard let directionParam = parameters["direction"],
                  let direction = MovementDirection(rawValue: directionParam)
            else { res.sendStatus(400); return }
            
            let source = CGEventSource(stateID: .hidSystemState)
            let tapLocation = CGEventTapLocation.cghidEventTap
            CGEvent(keyboardEventSource: source, virtualKey: direction.keyCode, keyDown: true)?.post(tap: tapLocation)
            CGEvent(keyboardEventSource: source, virtualKey: direction.keyCode, keyDown: false)?.post(tap: tapLocation)
            res.sendStatus(200)
        }
        
        app.get("/select") { _, res, _ in
            let script = """
            tell application "VoiceOver"
                tell vo cursor
                    perform action
                end tell
            end tell
            """
            guard let osa = NSAppleScript(source: script) else {
                res.sendStatus(500)
                return
            }
            
            var error: NSDictionary?
            let response = osa.executeAndReturnError(&error)
            if let error {
                res.sendStatus(501)
            }
            else {
                res.sendStatus(200)
            }
        }
        
        app.listen(80) {
            print("Listening on port 80")
        }

    }

    func voiceOverStatusDidChange() {
        print("voiceover-status: \(isVoiceOverEnabled)")
        if isVoiceOverEnabled {
            let shouldLaunch = (voiceOverTask?.isCancelled == true || voiceOverTask == nil)
            guard shouldLaunch else { return }
            runVoiceOverTask()
        }
        else {
            endVoiceOverTask()
        }
    }
    
    func runVoiceOverTask() {
        voiceOverTask = Task.detached(priority: .high) { [unowned self] in
            await self.run()
        }
    }
    
    func endVoiceOverTask() {
        voiceOverTask?.cancel()
        voiceOverTask = nil
    }
    
    private func run() async {
        let script = """
        tell application "VoiceOver"
            set phrase to get content of last phrase
            return phrase
        end tell
        """
        guard let osa = NSAppleScript(source: script) else { return }
        var previousResponse: String?
        while true {
            try? await Task.sleep(for: .seconds(0.1))
            guard !Task.isCancelled else { return }
            
            var error: NSDictionary?
            let response = osa.executeAndReturnError(&error)
            
            if let value = response.stringValue {
                guard value != previousResponse else { continue }
                previousResponse = value
                print(value)
                await setLatestPhrase(value)
            }
            else {
                print(error ?? [:])
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
    
    @MainActor func setLatestPhrase(_ phrase: String) {
        self.latestPhrase = phrase
    }
}
