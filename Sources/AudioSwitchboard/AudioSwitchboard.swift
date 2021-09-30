import AVFoundation
import Combine
import UIKit

typealias AudioSwitchboardSubject = PassthroughSubject<Void, Never>
public typealias AudioSwitchboardPublisher = AnyPublisher<Void, Never>
public class AudioSwitchboard :ObservableObject {
    public enum AvailableService: CaseIterable {
        case play
        case record
    }
    public var cancellables = Set<AnyCancellable>()
    public let audioEngine:AVAudioEngine
    
    @Published public private(set) var availableServices = [AvailableService]()
    @Published public private(set) var shouldBeRunning:Bool = false
    @Published public private(set) var currentOwner:String?
    private var subscribers = [String:AudioSwitchboardSubject]()
    public init(audioEngine:AVAudioEngine = .init(),startAudioSessionImmediately:Bool = true) {
        self.audioEngine = audioEngine
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification, object: nil).sink { [weak self] notif in
            self?.startAudioSession()
            
        }.store(in: &cancellables)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification, object: nil).sink { [weak self] notif in
            self?.startAudioSession()
        }.store(in: &cancellables)
        if startAudioSessionImmediately {
            startAudioSession()
        }
    }
    public func startAudioSession() {
        self.availableServices = self.activate()
    }
    public func stop(owner:String) {
        if owner != self.currentOwner {
            return
        }
        subscribers.forEach { key,value in
            if key != owner {
                value.send()
            }
        }
        subscribers.removeAll()
        reset()
    }
    public func reset() {
        debugPrint("resetting audioengine")
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.mainMixerNode.removeTap(onBus: 0)
        audioEngine.outputNode.removeTap(onBus: 0)
        audioEngine.inputNode.reset()
        audioEngine.mainMixerNode.reset()
        audioEngine.outputNode.reset()
        audioEngine.stop()
        audioEngine.attachedNodes.forEach { node in
            if node != audioEngine.outputNode && node != audioEngine.inputNode && node != audioEngine.mainMixerNode {
                audioEngine.detach(node)
                node.reset()
            }
        }
        audioEngine.reset()
        shouldBeRunning = false
    }
    public func start(owner:String) throws {
        if owner != self.currentOwner {
            return
        }
        audioEngine.prepare()
        try audioEngine.start()
        shouldBeRunning = true
    }
    @discardableResult public func claim(owner:String) -> AudioSwitchboardPublisher {
        self.currentOwner = owner
        stop(owner: owner)
        let p = AudioSwitchboardSubject()
        subscribers[owner] = p
        return p.eraseToAnyPublisher()
    }
    private func activate() -> [AvailableService]{
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers,.duckOthers,.interruptSpokenAudioAndMixWithOthers,.allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            return AvailableService.allCases
        } catch {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .mixWithOthers,.duckOthers,.interruptSpokenAudioAndMixWithOthers,.allowBluetooth])
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                return [AvailableService.play]
            } catch {
                return []
            }
        }
    }
}
