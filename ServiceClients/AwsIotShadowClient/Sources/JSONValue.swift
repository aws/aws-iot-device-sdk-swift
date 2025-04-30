import Foundation

public enum JSONValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case dictionary([String: JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else if let arrayVal = try? container.decode([JSONValue].self) {
            self = .array(arrayVal)
        } else if let dictVal = try? container.decode([String: JSONValue].self) {
            self = .dictionary(dictVal)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    // Converts JSONValue back to a plain Swift value.
    public func toAny() -> Any {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .bool(let value):
            return value
        case .array(let value):
            return value.map { $0.toAny() }
        case .dictionary(let value):
            var dict = [String: Any]()
            for (key, value) in value {
                dict[key] = value.toAny()
            }
            return dict
        case .null:
            return NSNull()
        }
    }

    // Converts a Swift value (of type Any) to a JSONValue.
    public static func fromAny(_ any: Any) -> JSONValue {
        switch any {
        case let value as String:
            return .string(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        case let value as Bool:
            return .bool(value)
        case let array as [Any]:
            return .array(array.map { JSONValue.fromAny($0) })
        case let dict as [String: Any]:
            var newDict = [String: JSONValue]()
            for (key, value) in dict {
                newDict[key] = JSONValue.fromAny(value)
            }
            return .dictionary(newDict)
        default:
            return .null
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    /// Converts a [String: Any] dictionary into a [String: JSONValue] dictionary.
    func asJSONValueDictionary() -> [String: JSONValue] {
        var dict = [String: JSONValue]()
        for (key, value) in self {
            dict[key] = JSONValue.fromAny(value)
        }
        return dict
    }
}

extension Dictionary where Key == String, Value == JSONValue {
    /// Converts a [String: JSONValue] dictionary back into a [String: Any] dictionary.
    func asAnyDictionary() -> [String: Any] {
        var dict = [String: Any]()
        for (key, value) in self {
            dict[key] = value.toAny()
        }
        return dict
    }
}
