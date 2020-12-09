import UIKit
import Ably
import CoreLocation

protocol AblySubscriberServiceDelegate: class {
    func subscriberService(sender: AblySubscriberService, didChangeAssetConnectionStatus status: AssetTrackingConnectionStatus)
    func subscriberService(sender: AblySubscriberService, didFailWithError error: Error)
    func subscriberService(sender: AblySubscriberService, didReceiveRawLocation location: CLLocation)
    func subscriberService(sender: AblySubscriberService, didReceiveEnhancedLocation location: CLLocation)
}

class AblySubscriberService {
    private let client: ARTRealtime
    private let clientId: String
    private let presenceData: PresenceData
    private let channel: ARTRealtimeChannel

    weak var delegate: AblySubscriberServiceDelegate?
    
    init(apiKey: String, clientId: String, trackingId: String) {
        self.client = ARTRealtime(key: apiKey)
        self.presenceData = PresenceData(type: .subscriber)
        self.clientId = clientId
        
        let options = ARTRealtimeChannelOptions()
        options.params = ["rewind": "1"]
        channel = client.channels.get(trackingId, options: options)
    }
    
    func start(completion: ((Error?) -> Void)?) {
        // Trigger offline event at start
        delegate?.subscriberService(sender: self, didChangeAssetConnectionStatus: .offline)
        channel.presence.subscribe({ [weak self] message in
            self?.handleIncomingPresenceMessage(message)
        })
        
        // Force cast intentional here. It's a fatal error if we are unable to create presenceData JSON
        let data = presenceData.toEncodedJSONString()!
        channel.presence.enterClient(clientId, data: data) { error in
            // TODO: Log suitable message when Logger become available:
            // https://github.com/ably/ably-asset-tracking-cocoa/issues/8
            completion?(error)
        }
        
        channel.subscribe(EventName.raw.rawValue) { [weak self] message in
            guard let strongSelf = self else { return }
            guard let json = message.data as? String,
                  let geoJSONMessages: [GeoJSONMessage] = [GeoJSONMessage].fromJSONString(json)
            else {
                strongSelf.delegate?.subscriberService(
                    sender: strongSelf,
                    didFailWithError: AblyError.inconsistentData("Cannot parse raw location message: \(message.data ?? "nil")")
                )
                return
            }
            
            geoJSONMessages.forEach {
                let location = $0.toCoreLocation()
                strongSelf.delegate?.subscriberService(sender: strongSelf, didReceiveRawLocation: location)
            }
        }
        
        channel.subscribe(EventName.enhanced.rawValue) { [weak self] message in
            guard let strongSelf = self else { return }
            guard let json = message.data as? String,
                  let geoJSONMessages: [GeoJSONMessage] = [GeoJSONMessage].fromJSONString(json)
            else {
                strongSelf.delegate?.subscriberService(
                    sender: strongSelf,
                    didFailWithError: AblyError.inconsistentData("Cannot parse enhanced location message: \(message.data ?? "nil")")
                )
                return
            }
            
            geoJSONMessages.forEach {
                let location = $0.toCoreLocation()
                strongSelf.delegate?.subscriberService(sender: strongSelf, didReceiveEnhancedLocation: location)
            }
        }
    }
    
    func stop() {
        channel.unsubscribe()
        leaveChannelPresence()
        client.close()
    }

    // MARK: Utils
    private func handleIncomingPresenceMessage(_ message: ARTPresenceMessage) {
        let supportedActions: [ARTPresenceAction] = [.present, .enter, .leave]
        guard supportedActions.contains(message.action),
              let dataJSON = message.data as? String,
              let data = dataJSON.data(using: .utf8),
              let presenceData = try? JSONDecoder().decode(PresenceData.self, from: data),
              presenceData.type == .publisher
        else { return }
              
        switch message.action {
        case .present, .enter:
            delegate?.subscriberService(sender: self, didChangeAssetConnectionStatus: .online)
        case .leave:
            delegate?.subscriberService(sender: self, didChangeAssetConnectionStatus: .offline)
        default: break
        }
    }
    
    private func leaveChannelPresence() {
        channel.presence.unsubscribe()
        delegate?.subscriberService(sender: self, didChangeAssetConnectionStatus: .offline)
        
        // Force cast intentional here. It's a fatal error if we are unable to create presenceData JSON
        let data = presenceData.toEncodedJSONString()!
        channel.presence.leaveClient(clientId, data: data) { [weak self] error in
            // TODO: Log suitable message when Logger become available:
            // https://github.com/ably/ably-asset-tracking-cocoa/issues/8
            if let error = error,
               let strongSelf = self {
                strongSelf.delegate?.subscriberService(sender: strongSelf, didFailWithError: error)
            }
        }
    }
}
