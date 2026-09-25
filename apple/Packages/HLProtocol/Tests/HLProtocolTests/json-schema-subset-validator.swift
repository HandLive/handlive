import Foundation

/// Bộ kiểm JSON Schema draft 2020-12 rút gọn — chỉ đúng các từ khóa `shared/schemas/` đang dùng:
/// `$ref` (tương đối giữa file + JSON pointer), `type`, `enum`, `const`, `required`, `properties`,
/// `additionalProperties`, `items`, `uniqueItems`, `minimum`, `maximum`, `minLength`, `pattern`,
/// `allOf`, `anyOf`, `not`, `if`/`then`/`else`. Từ khóa lạ → báo lỗi để không bỏ sót ràng buộc.
struct SchemaValidator {
    private static let annotations: Set<String> = ["$schema", "$id", "$defs", "title", "description"]
    private static let supported: Set<String> = [
        "$ref", "type", "enum", "const", "required", "properties", "additionalProperties", "items",
        "uniqueItems", "minimum", "maximum", "minLength", "pattern", "allOf", "anyOf", "not", "if", "then", "else"
    ]

    private let documents: [String: Any]

    init(directory: URL = RepoFiles.schemasDirectory) throws {
        var docs: [String: Any] = [:]
        for file in try FileManager.default.contentsOfDirectory(atPath: directory.path) where file.hasSuffix(".json") {
            docs[file] = try RepoFiles.json(at: directory.appendingPathComponent(file))
        }
        documents = docs
    }

    /// Trả danh sách lỗi (rỗng = hợp lệ). `ref` dạng `file.schema.json` hoặc `file.schema.json#/$defs/x`.
    func errors(_ instance: Any, ref: String) -> [String] {
        var errors: [String] = []
        let (file, schema) = resolve(ref, base: "")
        check(instance, schema, base: file, path: "$", errors: &errors)
        return errors
    }

    private func resolve(_ ref: String, base: String) -> (String, Any?) {
        let parts = ref.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let file = parts[0].isEmpty ? base : parts[0]
        var node: Any? = documents[file]
        if parts.count > 1 {
            for token in parts[1].split(separator: "/") {
                node = (node as? [String: Any])?[String(token)]
            }
        }
        return (file, node)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func check(_ value: Any, _ schemaNode: Any?, base: String, path: String, errors: inout [String]) {
        if let flag = schemaNode as? Bool {
            if !flag { errors.append("\(path): schema false") }
            return
        }
        guard let schema = schemaNode as? [String: Any] else {
            errors.append("\(path): schema không phân giải được")
            return
        }
        for key in schema.keys where !Self.supported.contains(key) && !Self.annotations.contains(key) {
            errors.append("\(path): từ khóa chưa hỗ trợ \(key)")
        }
        if let ref = schema["$ref"] as? String {
            let (file, target) = resolve(ref, base: base)
            check(value, target, base: file, path: path, errors: &errors)
        }
        if let type = schema["type"] {
            let names = (type as? [String]) ?? [type as? String ?? ""]
            if !names.contains(where: { JSONKind.matches(value, $0) }) {
                errors.append("\(path): sai kiểu, cần \(names)")
            }
        }
        if let options = schema["enum"] as? [Any], !options.contains(where: { JSONKind.equal($0, value) }) {
            errors.append("\(path): ngoài enum")
        }
        if let constant = schema["const"], !JSONKind.equal(constant, value) {
            errors.append("\(path): khác const")
        }
        if let number = JSONKind.number(value) {
            if let min = schema["minimum"] as? NSNumber, number.compare(min) == .orderedAscending {
                errors.append("\(path): nhỏ hơn minimum")
            }
            if let max = schema["maximum"] as? NSNumber, number.compare(max) == .orderedDescending {
                errors.append("\(path): lớn hơn maximum")
            }
        }
        if let text = value as? String {
            if let min = schema["minLength"] as? Int, text.unicodeScalars.count < min {
                errors.append("\(path): ngắn hơn minLength")
            }
            if let pattern = schema["pattern"] as? String,
               text.range(of: pattern, options: .regularExpression) == nil {
                errors.append("\(path): không khớp pattern \(pattern)")
            }
        }
        if let object = value as? [String: Any] {
            for key in schema["required"] as? [String] ?? [] where object[key] == nil {
                errors.append("\(path): thiếu \(key)")
            }
            let properties = schema["properties"] as? [String: Any] ?? [:]
            for (key, child) in object {
                if let sub = properties[key] {
                    check(child, sub, base: base, path: "\(path).\(key)", errors: &errors)
                } else if let extra = schema["additionalProperties"] {
                    check(child, extra, base: base, path: "\(path).\(key)", errors: &errors)
                }
            }
        }
        if let array = value as? [Any] {
            if let items = schema["items"] {
                for (index, item) in array.enumerated() {
                    check(item, items, base: base, path: "\(path)[\(index)]", errors: &errors)
                }
            }
            if schema["uniqueItems"] as? Bool == true {
                for first in array.indices {
                    for second in array.indices where second > first && JSONKind.equal(array[first], array[second]) {
                        errors.append("\(path): phần tử trùng")
                    }
                }
            }
        }
        for sub in schema["allOf"] as? [Any] ?? [] {
            check(value, sub, base: base, path: path, errors: &errors)
        }
        if let anyOf = schema["anyOf"] as? [Any],
           !anyOf.contains(where: { passes(value, $0, base: base) }) {
            errors.append("\(path): không khớp anyOf")
        }
        if let negated = schema["not"], passes(value, negated, base: base) {
            errors.append("\(path): khớp not")
        }
        if let condition = schema["if"] {
            let branch = passes(value, condition, base: base) ? schema["then"] : schema["else"]
            if let branch { check(value, branch, base: base, path: path, errors: &errors) }
        }
    }

    private func passes(_ value: Any, _ schema: Any, base: String) -> Bool {
        var errors: [String] = []
        check(value, schema, base: base, path: "$", errors: &errors)
        return errors.isEmpty
    }
}

/// Phân loại giá trị từ `JSONSerialization` theo kiểu JSON Schema.
enum JSONKind {
    static func isBool(_ value: Any) -> Bool {
        guard let number = value as? NSNumber else { return false }
        return CFGetTypeID(number) == CFBooleanGetTypeID()
    }

    static func number(_ value: Any) -> NSNumber? {
        guard let number = value as? NSNumber, !isBool(number) else { return nil }
        return number
    }

    static func matches(_ value: Any, _ kind: String) -> Bool {
        switch kind {
        case "null": return value is NSNull
        case "boolean": return isBool(value)
        case "number": return number(value) != nil
        case "integer":
            guard let number = number(value) else { return false }
            return number.doubleValue.rounded() == number.doubleValue
        case "string": return value is String
        case "array": return value is [Any]
        case "object": return value is [String: Any]
        default: return false
        }
    }

    static func equal(_ lhs: Any, _ rhs: Any) -> Bool {
        if isBool(lhs) || isBool(rhs) {
            return isBool(lhs) && isBool(rhs) && (lhs as? Bool) == (rhs as? Bool)
        }
        if let left = number(lhs), let right = number(rhs) { return left.compare(right) == .orderedSame }
        if let left = lhs as? String, let right = rhs as? String { return left == right }
        if lhs is NSNull, rhs is NSNull { return true }
        if let left = lhs as? [Any], let right = rhs as? [Any] {
            return left.count == right.count && zip(left, right).allSatisfy { equal($0, $1) }
        }
        if let left = lhs as? [String: Any], let right = rhs as? [String: Any] {
            return left.count == right.count && left.allSatisfy { key, value in
                right[key].map { equal(value, $0) } ?? false
            }
        }
        return false
    }
}
