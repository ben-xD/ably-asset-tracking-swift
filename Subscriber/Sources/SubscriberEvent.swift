import CoreLocation

protocol SubscriberEvent {}

struct StartEvent: SubscriberEvent {
    let resultHandler: ResultHandler<Void>
}

struct StopEvent: SubscriberEvent {
    let resultHandler: ResultHandler<Void>
}

struct ChangeResolutionEvent: SubscriberEvent {
    let resolution: Resolution?
    let resultHandler: ResultHandler<Void>
}

struct PresenceUpdateEvent: SubscriberEvent {
    let presence: AblyPresence
}

struct AblyConnectionClosedEvent: SubscriberEvent {
    let resultHandler: ResultHandler<Void>
}

struct AblyClientConnectionStateChangedEvent: SubscriberEvent {
    let connectionState: ConnectionState
}

struct AblyChannelConnectionStateChangedEvent: SubscriberEvent {
    let connectionState: ConnectionState
}

// MARK: Delegate handling events

protocol SubscriberDelegateEvent {}

struct DelegateErrorEvent: SubscriberDelegateEvent {
    let error: ErrorInformation
}

struct DelegateEnhancedLocationReceivedEvent: SubscriberDelegateEvent {
    let location: CLLocation
}

struct DelegateConnectionStatusChangedEvent: SubscriberDelegateEvent {
    let status: ConnectionState
}
