import Flutter
import UIKit
import BackgroundTasks

/// I-05：iOS 后台生成——BGAppRefreshTask + beginBackgroundTask 短延保 + 通知。
@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "app.ios_background_generation"
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
  private var pendingUpdate: String?
  private var pendingFinished = false
  private var drainScheduled = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "start":
        self?.startBackgroundTask()
        result(nil)
      case "scheduleUpdate":
        let args = call.arguments as? [String: Any] ?? [:]
        let content = args["content"] as? String ?? ""
        let finished = args["finished"] as? Bool ?? false
        let cancelled = args["cancelled"] as? Bool ?? false
        self?.scheduleUpdate(content: content, finished: finished, cancelled: cancelled)
        result(nil)
      case "finish":
        self?.finishBackgroundTask()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // BGTask 注册
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.nona.chat.bgrefresh",
      using: nil
    ) { task in
      self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 开始后台窗口（beginBackgroundTask 短延保，最多约 30 秒）。
  private func startBackgroundTask() {
    if backgroundTaskId != .invalid { return }
    backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
      self?.endBackgroundTask()
    }
    // 完成通知权限（首次使用请求；拒绝后静默跳过通知）
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    scheduleAppRefresh()
  }

  /// 更新内容（latest-wins：只保留最新，串行排空）。
  private func scheduleUpdate(content: String, finished: Bool, cancelled: Bool) {
    pendingUpdate = content
    pendingFinished = finished || cancelled
    guard !drainScheduled else { return }
    drainScheduled = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.drainScheduled = false
      guard let self else { return }
      let content = self.pendingUpdate ?? ""
      self.pendingUpdate = nil
      let finished = self.pendingFinished
      if finished {
        self.postCompletionNotification(content: content)
        self.endBackgroundTask()
      }
    }
  }

  private func endBackgroundTask() {
    guard backgroundTaskId != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTaskId)
    backgroundTaskId = .invalid
  }

  private func finishBackgroundTask() {
    if let content = pendingUpdate, !content.isEmpty {
      postCompletionNotification(content: content)
    }
    endBackgroundTask()
  }

  /// 完成通知。
  private func postCompletionNotification(content: String) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      guard settings.authorizationStatus == .authorized else { return }
      let notification = UNMutableNotificationContent()
      notification.title = "Nona"
      notification.body = content.count > 60 ? String(content.prefix(60)) + "…" : content
      let request = UNNotificationRequest(
        identifier: "com.nona.chat.completed",
        content: notification,
        trigger: nil)
      center.add(request)
    }
  }

  /// 注册 BGAppRefreshTask（系统后台窗口）。
  private func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.nona.chat.bgrefresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 5)
    try? BGTaskScheduler.shared.submit(request)
  }

  private func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefresh()
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
    // 触发 Dart 侧继续生成（通过事件）
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: controller.binaryMessenger)
    channel.invokeMethod("onAppRefresh", arguments: nil)
    task.setTaskCompleted(success: true)
  }
}
