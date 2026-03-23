import XCTest
@testable import PodWatch

final class BluetoothBatteryParserTests: XCTestCase {
    private let parser = BluetoothBatteryParser()

    func testParsesSelectedDeviceByAddress() throws {
        let snapshots = try parser.parse(data: sampleJSON.data(using: .utf8)!)
        let device = try XCTUnwrap(snapshots.first { $0.address == "11-22-33-44-55-66" })

        XCTAssertEqual(device.name, "Office AirPods Pro")
        XCTAssertTrue(device.isConnected)
        XCTAssertEqual(device.leftBattery, 4)
        XCTAssertEqual(device.rightBattery, 57)
        XCTAssertEqual(device.caseBattery, 85)
    }

    func testKeepsDuplicateNamesWithDifferentAddresses() throws {
        let snapshots = try parser.parse(data: sampleJSON.data(using: .utf8)!)
        let duplicateNameDevices = snapshots.filter { $0.name == "Office AirPods Pro" }

        XCTAssertEqual(duplicateNameDevices.map(\.address).sorted(), [
            "11-22-33-44-55-66",
            "AA-BB-CC-DD-EE-FF"
        ])
    }

    func testHandlesMissingLeftAndRightBatteryValues() throws {
        let snapshots = try parser.parse(data: sampleJSON.data(using: .utf8)!)
        let device = try XCTUnwrap(snapshots.first { $0.address == "77-88-99-AA-BB-CC" })

        XCTAssertNil(device.leftBattery)
        XCTAssertNil(device.rightBattery)
        XCTAssertEqual(device.mainBattery, 41)
    }

    func testParsesStringFormattedAndNumericBatteryValues() throws {
        let snapshots = try parser.parse(data: sampleJSON.data(using: .utf8)!)
        let device = try XCTUnwrap(snapshots.first { $0.address == "AA-BB-CC-DD-EE-FF" })

        XCTAssertEqual(device.leftBattery, 33)
        XCTAssertEqual(device.rightBattery, 66)
    }

    func testPreservesDisconnectedDeviceSnapshots() throws {
        let snapshots = try parser.parse(data: sampleJSON.data(using: .utf8)!)
        let device = try XCTUnwrap(snapshots.first { $0.address == "AA-BB-CC-DD-EE-FF" })

        XCTAssertFalse(device.isConnected)
    }

    func testParsesDynamicDeviceKeyAsFriendlyName() throws {
        let snapshots = try parser.parse(data: dynamicKeyJSON.data(using: .utf8)!)
        let device = try XCTUnwrap(snapshots.first { $0.address == "00:11:22:33:44:55" })

        XCTAssertEqual(device.name, "Example AirPods")
        XCTAssertTrue(device.isConnected)
        XCTAssertEqual(device.leftBattery, 5)
        XCTAssertEqual(device.rightBattery, 15)
        XCTAssertEqual(device.caseBattery, 66)
    }
}

private let sampleJSON = """
{
  "SPBluetoothDataType": [
    {
      "_name": "Bluetooth",
      "_items": [
        {
          "device_defaultName": "Office AirPods Pro",
          "device_address": "11-22-33-44-55-66",
          "device_connected": "Connected",
          "device_batteryLevelLeft": 0.04,
          "device_batteryLevelRight": 57,
          "device_batteryLevelCase": "85%"
        },
        {
          "device_defaultName": "Office AirPods Pro",
          "device_address": "AA-BB-CC-DD-EE-FF",
          "device_connected": "Not Connected",
          "device_batteryLevelLeft": "33%",
          "device_batteryLevelRight": "0.66"
        },
        {
          "device_defaultName": "Studio AirPods Max",
          "device_address": "77-88-99-AA-BB-CC",
          "device_connected": false,
          "device_batteryLevelMain": "41%"
        }
      ]
    }
  ]
}
"""

private let dynamicKeyJSON = """
{
  "SPBluetoothDataType": [
    {
      "device_connected": [
        {
          "Example AirPods": {
            "device_address": "00:11:22:33:44:55",
            "device_batteryLevelCase": "66%",
            "device_batteryLevelLeft": "5%",
            "device_batteryLevelRight": "15%",
            "device_minorType": "Headphones"
          }
        }
      ]
    }
  ]
}
"""
