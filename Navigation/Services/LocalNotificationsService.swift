//
//  LocalNotificationsService.swift
//  Navigation
//

import UIKit
import UserNotifications

final class LocalNotificationsService: NSObject {

    static let shared = LocalNotificationsService()

    private let updatesCategoryIdentifier = "updates"
    private let openUpdatesActionIdentifier = "OPEN_UPDATES_ACTION"
    private let updatesNotificationIdentifier = "latestUpdatesDailyReminder"

    private override init() {
        super.init()
    }

    // MARK: - Задача 1

    /// Запрашивает разрешение на уведомления (звук, бейдж, алерт) и,
    /// если пользователь согласился, регистрирует ежедневное уведомление в 19:00
    func registerForLatestUpdatesIfPossible() {
        // Задача 2*: категория с действием регистрируется до запроса разрешения
        registerUpdatesCategory()

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.sound, .badge, .alert]) { [weak self] granted, error in
            if let error = error {
                print("❌ Ошибка запроса разрешения на уведомления: \(error.localizedDescription)")
                return
            }

            guard granted else {
                print("🔕 Пользователь не разрешил уведомления")
                return
            }

            print("🔔 Доступ к уведомлениям получен")
            self?.scheduleDailyUpdatesNotification()
        }
    }

    private func scheduleDailyUpdatesNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ВК"
        content.body = "Посмотрите последние обновления"
        content.sound = .default
        content.badge = 1
        // Задача 2*: привязываем уведомление к категории с действием
        content.categoryIdentifier = updatesCategoryIdentifier

        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: updatesNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Не удалось запланировать уведомление: \(error.localizedDescription)")
            } else {
                print("✅ Ежедневное уведомление в 19:00 запланировано")
            }
        }
    }

    // MARK: - Задача 2*

    /// Регистрирует категорию "updates" с действием "Открыть обновления"
    func registerUpdatesCategory() {
        let openUpdatesAction = UNNotificationAction(
            identifier: openUpdatesActionIdentifier,
            title: "Открыть обновления",
            options: [.foreground]
        )

        let updatesCategory = UNNotificationCategory(
            identifier: updatesCategoryIdentifier,
            actions: [openUpdatesAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([updatesCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LocalNotificationsService: UNUserNotificationCenterDelegate {

    /// Позволяет показывать уведомление, даже если приложение в этот момент активно
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.sound, .badge, .banner, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case openUpdatesActionIdentifier:
            // Действие на выбор: переключаем приложение на вкладку "Лента",
            // чтобы пользователь сразу увидел обновления
            print("👉 Пользователь выбрал «Открыть обновления»")
            (UIApplication.shared.delegate as? AppDelegate)?.showFeedTabForLatestUpdates()
        case UNNotificationDefaultActionIdentifier:
            print("👉 Пользователь тапнул по самому уведомлению")
            (UIApplication.shared.delegate as? AppDelegate)?.showFeedTabForLatestUpdates()
        default:
            break
        }

        completionHandler()
    }
}
