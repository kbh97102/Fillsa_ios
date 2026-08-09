//
//  FiilsaTests.swift
//  FiilsaTests
//
//  Created by 강보훈 on 6/13/26.
//

import Testing
import Foundation
import SwiftUI
import UIKit
@testable import Fiilsa

struct FiilsaTests {

    @Test func dailyQuote_decodesMemberPayloadWithoutQuoteDate() throws {
        let responseBody = """
        {
          "likeYn": "N",
          "imagePath": null,
          "dailyQuoteSeq": 30419,
          "korQuote": "아무것도 모르는 것보다는 쓸모없는 것이라도 아는 편이 낫다.",
          "engQuote": "It is better to know useless things than to know nothing.",
          "korAuthor": "세네카",
          "engAuthor": "Seneca",
          "authorUrl": "https://ko.wikipedia.org/wiki/세네카"
        }
        """

        let quote = try JSONDecoder().decode(DailyQuote.self, from: Data(responseBody.utf8))

        #expect(quote.dailyQuoteSeq == 30419)
        #expect(quote.quoteDate == "")
    }

    @Test func pushRegistrationRequest_usesServerFieldNames() throws {
        let request = PushRegistrationRequest(
            deviceId: "device-id",
            pushToken: "fcm-token",
            agreed: true
        )

        let data = try JSONEncoder().encode(request)
        let body = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(body?["deviceId"] as? String == "device-id")
        #expect(body?["pushToken"] as? String == "fcm-token")
        #expect(body?["agreed"] as? Bool == true)
    }

    @Test func deviceData_omitsPushFieldsWhenFCMTokenIsUnavailable() throws {
        let deviceData = DeviceData(
            deviceId: "device-id",
            osType: "IOS",
            appVersion: "1.0.26",
            osVersion: "18.0",
            deviceModel: "iPhone",
            pushToken: nil,
            pushAgreed: nil
        )

        let data = try JSONEncoder().encode(deviceData)
        let body = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(body?["pushToken"] == nil)
        #expect(body?["pushAgreed"] == nil)
    }

    @Test @MainActor func noticeList_usesFigmaTextColorsInDarkMode() {
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)
        let darkTrait = UITraitCollection(userInterfaceStyle: .dark)

        #expect(resolvedHex(NoticeListPalette.date, trait: lightTrait) == 0x9E9E9E)
        #expect(resolvedHex(NoticeListPalette.title, trait: lightTrait) == 0x212121)
        #expect(resolvedHex(NoticeListPalette.date, trait: darkTrait) == 0xE0E0E0)
        #expect(resolvedHex(NoticeListPalette.title, trait: darkTrait) == 0xFFFFFF)
    }

    @MainActor
    private func resolvedHex(_ color: Color, trait: UITraitCollection) -> UInt? {
        let resolvedColor = UIColor(color).resolvedColor(with: trait)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return (UInt((red * 255).rounded()) << 16)
            | (UInt((green * 255).rounded()) << 8)
            | UInt((blue * 255).rounded())
    }

}
