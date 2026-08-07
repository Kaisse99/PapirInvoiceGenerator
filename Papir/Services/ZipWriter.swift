//
//  ZipWriter.swift
//  A zip archive built by hand, because an xlsx is a zip with its parts at the
//  archive root and the only zipper in the system frameworks, NSFileCoordinator
//  with its uploading option, insists on nesting everything under a folder.
//  Entries are stored rather than deflated: the whole export is a few dozen
//  kilobytes of text, so the compression would save nothing worth the extra
//  moving parts, and every reader accepts stored entries.
//  Names are written as UTF-8 with the language encoding flag set, since a
//  sheet or a file could carry a Cyrillic name later even though none does
//  today.
//  Used by: XLSXWriter.
//

import Foundation

struct ZipWriter {
    private struct Entry {
        let name: String
        let crc: UInt32
        let size: UInt32
        let offset: UInt32
    }

    private var payload = Data()
    private var entries: [Entry] = []

    mutating func add(_ contents: Data, named name: String) {
        let nameBytes = Array(name.utf8)
        let crc = CRC32.checksum(contents)
        let offset = UInt32(payload.count)

        payload.append(contentsOf: [0x50, 0x4B, 0x03, 0x04])
        payload.append(uint16(20))
        payload.append(uint16(0x0800))
        payload.append(uint16(0))
        payload.append(uint16(0))
        payload.append(uint16(0))
        payload.append(uint32(crc))
        payload.append(uint32(UInt32(contents.count)))
        payload.append(uint32(UInt32(contents.count)))
        payload.append(uint16(UInt16(nameBytes.count)))
        payload.append(uint16(0))
        payload.append(contentsOf: nameBytes)
        payload.append(contents)

        entries.append(
            Entry(name: name, crc: crc, size: UInt32(contents.count), offset: offset)
        )
    }

    mutating func add(_ text: String, named name: String) {
        add(Data(text.utf8), named: name)
    }

    func finish() -> Data {
        var archive = payload
        let directoryOffset = UInt32(archive.count)

        for entry in entries {
            let nameBytes = Array(entry.name.utf8)
            archive.append(contentsOf: [0x50, 0x4B, 0x01, 0x02])
            archive.append(uint16(20))
            archive.append(uint16(20))
            archive.append(uint16(0x0800))
            archive.append(uint16(0))
            archive.append(uint16(0))
            archive.append(uint16(0))
            archive.append(uint32(entry.crc))
            archive.append(uint32(entry.size))
            archive.append(uint32(entry.size))
            archive.append(uint16(UInt16(nameBytes.count)))
            archive.append(uint16(0))
            archive.append(uint16(0))
            archive.append(uint16(0))
            archive.append(uint16(0))
            archive.append(uint32(0))
            archive.append(uint32(entry.offset))
            archive.append(contentsOf: nameBytes)
        }

        let directorySize = UInt32(archive.count) - directoryOffset

        archive.append(contentsOf: [0x50, 0x4B, 0x05, 0x06])
        archive.append(uint16(0))
        archive.append(uint16(0))
        archive.append(uint16(UInt16(entries.count)))
        archive.append(uint16(UInt16(entries.count)))
        archive.append(uint32(directorySize))
        archive.append(uint32(directoryOffset))
        archive.append(uint16(0))

        return archive
    }

    private func uint16(_ value: UInt16) -> Data {
        Data([UInt8(value & 0xFF), UInt8(value >> 8 & 0xFF)])
    }

    private func uint32(_ value: UInt32) -> Data {
        Data([
            UInt8(value & 0xFF),
            UInt8(value >> 8 & 0xFF),
            UInt8(value >> 16 & 0xFF),
            UInt8(value >> 24 & 0xFF)
        ])
    }
}

enum CRC32 {
    private static let table: [UInt32] = (0...255).map { index -> UInt32 in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = value & 1 == 1 ? 0xEDB88320 ^ (value >> 1) : value >> 1
        }
        return value
    }

    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}
