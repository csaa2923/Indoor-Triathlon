import SwiftUI
import HealthKit
import WatchConnectivity

@main
struct StudioTriWatchApp: App {
    @StateObject private var workout = PulseWorkout()
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("STUDIO TRI").font(.caption).foregroundStyle(.mint)
                Text(workout.bpm.map { "\($0) ♥" } ?? "– ♥").font(.largeTitle).monospacedDigit()
                Text(workout.message).font(.caption2).multilineTextAlignment(.center)
                Button(workout.running ? "Beenden" : "Starten") {
                    if workout.running { workout.stop() } else { workout.start() }
                }.tint(workout.running ? .red : .mint)
            }.padding()
        }
    }
}

final class PulseWorkout: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, WCSessionDelegate {
    @Published var bpm: Int?
    @Published var running = false
    @Published var message = "Training starten"
    private let health = HKHealthStore()
    private var workout: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func start() {
        guard !running, HKHealthStore.isHealthDataAvailable(),
              let heartType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            message = "HealthKit nicht verfügbar"
            return
        }
        health.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [heartType]) { [weak self] authorized, error in
            DispatchQueue.main.async {
                guard authorized, error == nil else { self?.message = "Health-Zugriff prüfen"; return }
                self?.beginWorkout()
            }
        }
    }

    private func beginWorkout() {
        do {
            let config = HKWorkoutConfiguration()
            config.activityType = .mixedCardio
            config.locationType = .indoor
            let session = try HKWorkoutSession(healthStore: health, configuration: config)
            let live = session.associatedWorkoutBuilder()
            live.dataSource = HKLiveWorkoutDataSource(healthStore: health, workoutConfiguration: config)
            session.delegate = self
            live.delegate = self
            workout = session
            builder = live
            session.startActivity(with: Date())
            live.beginCollection(withStart: Date()) { [weak self] success, error in
                DispatchQueue.main.async {
                    self?.running = success
                    self?.message = success ? "Puls wird erfasst" : (error?.localizedDescription ?? "Start fehlgeschlagen")
                }
            }
        } catch { message = error.localizedDescription }
    }

    func stop() {
        workout?.end()
        running = false
        bpm = nil
        message = "Beendet"
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate), collectedTypes.contains(type),
              let reading = workoutBuilder.statistics(for: type)?.mostRecentQuantity() else { return }
        let value = Int(reading.doubleValue(for: HKUnit.count().unitDivided(by: .minute())).rounded())
        guard (35...230).contains(value) else { return }
        DispatchQueue.main.async { [weak self] in self?.bpm = value }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["bpm": value, "timestamp": Date().timeIntervalSince1970 * 1000], replyHandler: nil, errorHandler: nil)
        }
    }
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended {
            builder?.endCollection(withEnd: date) { [weak self] _, _ in
                self?.builder?.finishWorkout { _, _ in
                    DispatchQueue.main.async { self?.builder = nil; self?.workout = nil }
                }
            }
        }
    }
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in self?.running = false; self?.message = error.localizedDescription }
    }
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        DispatchQueue.main.async { [weak self] in
            if action == "start" { self?.start() }
            if action == "stop" { self?.stop() }
        }
    }
}
