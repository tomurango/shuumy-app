//
//  RunnerUITests.swift
//  RunnerUITests
//
//  Created by 戸村英史 on 2026/02/13.
//

import XCTest

final class RunnerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    // MARK: - スクリーンショット自動生成

    @MainActor
    func testTakeScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // ホーム画面が表示されるまで待機
        sleep(3)

        // 1. ホーム画面
        snapshot("01_HomeScreen")

        // 画面下部のタブや要素を探してタップ（設定画面へ）
        // Flutterアプリの場合、座標ベースのタップが必要な場合があります
        sleep(1)

        // 画面右下の設定アイコンをタップ（座標は調整が必要な場合があります）
        let settingsButton = app.buttons.element(boundBy: 1)
        if settingsButton.exists {
            settingsButton.tap()
            sleep(2)
            snapshot("02_SettingsScreen")

            // 戻る
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // 趣味カードをタップして詳細画面へ
        // 最初のセル/カードをタップ
        let firstCell = app.cells.element(boundBy: 0)
        if firstCell.exists {
            firstCell.tap()
            sleep(2)
            snapshot("03_DetailScreen")

            // 戻る
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // その他のスクリーンショットが必要な場合はここに追加
    }

    // MARK: - パフォーマンステスト

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
