import Foundation

struct BluetoothBatteryParser {
    func parse(data: Data) throws -> [BluetoothDeviceSnapshot] {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        var deviceDictionaries: [[String: Any]] = []
        collectDeviceDictionaries(in: jsonObject, sectionHint: nil, into: &deviceDictionaries)

        var mergedSnapshots: [String: BluetoothDeviceSnapshot] = [:]

        for dictionary in deviceDictionaries {
            guard let snapshot = snapshot(from: dictionary) else {
                continue
            }

            if let existingSnapshot = mergedSnapshots[snapshot.address] {
                mergedSnapshots[snapshot.address] = existingSnapshot.merging(with: snapshot)
            } else {
                mergedSnapshots[snapshot.address] = snapshot
            }
        }

        return mergedSnapshots.values.sorted {
            let nameComparison = $0.name.localizedCaseInsensitiveCompare($1.name)
            if nameComparison == .orderedSame {
                return $0.address < $1.address
            }

            return nameComparison == .orderedAscending
        }
    }

    private func collectDeviceDictionaries(in value: Any, sectionHint: String?, into output: inout [[String: Any]]) {
        if let dictionary = value as? [String: Any] {
            if
                dictionary.count == 1,
                let (dynamicName, nestedValue) = dictionary.first,
                let nestedDictionary = nestedValue as? [String: Any],
                nestedDictionary["device_address"] != nil || nestedDictionary["address"] != nil
            {
                var decoratedDictionary = nestedDictionary

                if decoratedDictionary["device_defaultName"] == nil && decoratedDictionary["name"] == nil {
                    decoratedDictionary["device_defaultName"] = dynamicName
                }

                if let sectionHint {
                    decoratedDictionary["device_connected"] = (sectionHint == "device_connected")
                }

                output.append(decoratedDictionary)
                return
            }

            if dictionary["device_address"] != nil || dictionary["address"] != nil {
                output.append(dictionary)
            }

            for (key, nestedValue) in dictionary {
                let nextSectionHint: String?
                if key == "device_connected" || key == "device_not_connected" {
                    nextSectionHint = key
                } else {
                    nextSectionHint = sectionHint
                }

                collectDeviceDictionaries(in: nestedValue, sectionHint: nextSectionHint, into: &output)
            }
        } else if let array = value as? [Any] {
            for element in array {
                collectDeviceDictionaries(in: element, sectionHint: sectionHint, into: &output)
            }
        }
    }

    private func snapshot(from dictionary: [String: Any]) -> BluetoothDeviceSnapshot? {
        guard
            let address = stringValue(forKeys: ["device_address", "address"], in: dictionary)?.trimmingCharacters(in: .whitespacesAndNewlines),
            !address.isEmpty
        else {
            return nil
        }

        let name = stringValue(forKeys: ["device_defaultName", "name", "_name"], in: dictionary) ?? address

        let leftBattery = batteryValue(forKeys: ["device_batteryLevelLeft", "batteryLevelLeft"], in: dictionary)
        let rightBattery = batteryValue(forKeys: ["device_batteryLevelRight", "batteryLevelRight"], in: dictionary)
        let caseBattery = batteryValue(forKeys: ["device_batteryLevelCase", "batteryLevelCase"], in: dictionary)
        let mainBattery = batteryValue(forKeys: ["device_batteryLevelMain", "batteryLevelMain"], in: dictionary)

        let isConnected = boolValue(forKeys: ["device_connected", "connected"], in: dictionary)
            ?? (leftBattery != nil || rightBattery != nil || mainBattery != nil)

        return BluetoothDeviceSnapshot(
            name: name,
            address: address,
            isConnected: isConnected,
            leftBattery: leftBattery,
            rightBattery: rightBattery,
            caseBattery: caseBattery,
            mainBattery: mainBattery
        )
    }

    private func stringValue(forKeys keys: [String], in dictionary: [String: Any]) -> String? {
        for key in keys {
            guard let value = dictionary[key] else {
                continue
            }

            if let string = value as? String, !string.isEmpty {
                return string
            }

            if let number = value as? NSNumber {
                return number.stringValue
            }
        }

        return nil
    }

    private func batteryValue(forKeys keys: [String], in dictionary: [String: Any]) -> Int? {
        for key in keys {
            guard let value = dictionary[key] else {
                continue
            }

            if let percentage = percentageValue(from: value) {
                return percentage
            }
        }

        return nil
    }

    private func boolValue(forKeys keys: [String], in dictionary: [String: Any]) -> Bool? {
        for key in keys {
            guard let value = dictionary[key] else {
                continue
            }

            if let boolean = value as? Bool {
                return boolean
            }

            if let number = value as? NSNumber {
                return number.boolValue
            }

            if let string = value as? String {
                let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                if normalized.isEmpty {
                    continue
                }

                if normalized.contains("not connected") || normalized == "no" || normalized == "false" {
                    return false
                }

                if normalized == "yes" || normalized == "true" || normalized == "connected" {
                    return true
                }
            }
        }

        return nil
    }

    private func percentageValue(from value: Any) -> Int? {
        if let number = value as? NSNumber {
            return normalizePercentage(number.doubleValue)
        }

        guard let string = value as? String else {
            return nil
        }

        let normalized = string.replacingOccurrences(of: ",", with: ".")
        let extracted = normalized.filter { "0123456789.-".contains($0) }

        guard let number = Double(extracted) else {
            return nil
        }

        return normalizePercentage(number)
    }

    private func normalizePercentage(_ rawValue: Double) -> Int? {
        guard rawValue.isFinite, rawValue >= 0 else {
            return nil
        }

        let percentage: Double
        if rawValue > 0, rawValue <= 1 {
            percentage = rawValue * 100
        } else {
            percentage = rawValue
        }

        return min(max(Int(percentage.rounded()), 0), 100)
    }
}

private extension BluetoothDeviceSnapshot {
    func merging(with other: BluetoothDeviceSnapshot) -> BluetoothDeviceSnapshot {
        BluetoothDeviceSnapshot(
            name: preferredName(comparedTo: other),
            address: address,
            isConnected: isConnected || other.isConnected,
            leftBattery: other.leftBattery ?? leftBattery,
            rightBattery: other.rightBattery ?? rightBattery,
            caseBattery: other.caseBattery ?? caseBattery,
            mainBattery: other.mainBattery ?? mainBattery
        )
    }

    private func preferredName(comparedTo other: BluetoothDeviceSnapshot) -> String {
        if name == address, other.name != other.address {
            return other.name
        }

        return name
    }
}
