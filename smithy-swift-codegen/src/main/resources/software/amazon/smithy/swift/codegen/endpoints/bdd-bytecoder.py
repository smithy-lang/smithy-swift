#!/usr/bin/env python3
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0.

"""
BDD Bytecode Compiler: JSON -> binary bytecode format.

BYTECODE FORMAT SPECIFICATION
=============================
All multi-byte integers are big-endian (network byte order).

TOP-LEVEL STRUCTURE:
    [4 bytes]  Magic: 0x45504452 ("EPDR")
    [String Blob Section]
    [4 bytes]  Version string reference
    [Parameters Section]
    [Conditions Section]
    [Results Section]
    [Nodes Section]

STRING BLOB SECTION:
    [4 bytes]  blob_size (uint32)
    [blob_size bytes]  Concatenated ASCII strings, each terminated with "$$".

STRING REFERENCE (used throughout):
    [2 bytes]  offset (uint16) - byte offset into string blob
    [2 bytes]  length (uint16) - string length in bytes
    Note: (0, 0) represents empty/null string

PARAMETERS SECTION:
    [2 bytes]  count (uint16)
    [for each parameter:]
        [1 byte]   opcode: 0x01=string, 0x02=boolean, 0x03=string_array
        [4 bytes]  name string ref
        [1 byte]   has_default: 0=no, 1=yes
        [if has_default and string: 4 bytes string ref]
        [if has_default and bool: 1 byte value]
        [1 byte]   is_required: 0=no, 1=yes
        [1 byte]   has_builtin: 0=no, 1=yes
        [if has_builtin: 4 bytes builtin name string ref]

CONDITIONS SECTION:
    [2 bytes]  count (uint16)
    [for each condition:]
        [1 byte]   opcode: 0x10
        [4 bytes]  function name string ref
        [2 bytes]  argc (uint16)
        [argc encoded values]
        [1 byte]   has_assign: 0=no, 1=yes
        [if has_assign: 4 bytes assign name string ref]

RESULTS SECTION:
    [2 bytes]  count (uint16)
    Note: Loader inserts synthetic "NoMatchRule" at index 0; serialized results map to indices 1+
    [for each result:]
        Endpoint (opcode 0x20):
            [1 byte]   opcode: 0x20
            [encoded expr]  url
            [4 bytes]  properties_json string ref
            [2 bytes]  headers count
            [for each header:]
                [4 bytes]  header name string ref
                [2 bytes]  values count
                [encoded expr] header values
        Error (opcode 0x21):
            [1 byte]   opcode: 0x21
            [encoded expr]  error message

VALUE ENCODING (recursive):
    [1 byte]  tag
    Tag 0 (None):     no additional data
    Tag 1 (String):   [4 bytes] string ref
    Tag 2 (Boolean):  [1 byte] value (0=false, 1=true)
    Tag 3 (Integer):  [4 bytes] int32
    Tag 4 (Reference):[4 bytes] variable name string ref
    Tag 5 (Function): [4 bytes] fn name ref + [2 bytes] argc + [argc encoded values]
    Tag 6 (Array):    [2 bytes] length + [length encoded values]
    Tag 7 (Object):   [2 bytes] length + [for each: 4 bytes key ref + encoded value]

NODES SECTION:
    [4 bytes]  root_ref (int32) - root node reference
    [4 bytes]  node_count (uint32)
    [2 bytes]  base64_length (uint16)
    [1 byte]   padding
    [n bytes]  0 padding bytes specified by padding
    [base64_length bytes]  Base64-encoded node array

    Each node (after decoding) is 12 bytes:
        [4 bytes]  condition_index (int32) - index into conditions array
        [4 bytes]  high_ref (int32) - reference when condition is true
        [4 bytes]  low_ref (int32) - reference when condition is false

    Node references: positive = node index, negative = negated result index
    (e.g., -1 = result[0], -2 = result[1])

Use --verify flag to dump a human-readable summary of a compiled .bin file.
"""

import base64
import json
import struct
import sys
from enum import IntEnum

MAGIC = 0x45504452

fn_mapping = {"isSet" : 0, "not" : 1, "getAttr" : 2, "substring" : 3, "stringEquals" : 4, "booleanEquals" : 5, "coalesce" : 6,
               "split" : 7, "ite" : 8, "uriEncode" : 9, "parseURL" : 10, "isValidHostLabel" : 11, "aws.partition" : 12, "aws.parseArn" : 13, "aws.isVirtualHostableS3Bucket" : 14 }


class Opcode(IntEnum):
    PARAM_STRING = 0x01
    PARAM_BOOL = 0x02
    PARAM_STRING_ARRAY = 0x03
    CONDITION = 0x10
    RESULT_ENDPOINT = 0x20
    RESULT_ERROR = 0x21


class StringBlob:
    """Collects unique strings into one concatenated blob; returns (offset, length) pairs."""

    def __init__(self):
        self._blob = bytearray()
        self._index = {}  # str -> (offset, length)
        self._terminator = b"$$"

    def add(self, s):
        if not s:
            return (0, 0)
        if s not in self._index:
            if not s.isascii():
                raise ValueError(f"Non-ASCII string not supported: {s!r}")
            raw = s.encode("ascii")
            offset = len(self._blob)
            if offset > 0xFFFF:
                raise ValueError(f"String blob offset {offset} exceeds uint16 max")
            if len(raw) > 0xFFFF:
                raise ValueError(f"String length {len(raw)} exceeds uint16 max")
            self._blob.extend(raw)
            self._blob.extend(self._terminator)
            self._index[s] = (offset, len(raw))
        return self._index[s]

    def blob(self):
        return bytes(self._blob)


def write_string_ref(buf, offset, length):
    """Emit 4 bytes: uint16 offset + uint16 length (little-endian)."""
    buf.extend(struct.pack("<HH", offset, length))


def encode_value(buf, val, strings):
    """Recursively encode a value with type tag (0-7)."""
    if val is None:
        buf += struct.pack("<B", 0)
    elif isinstance(val, bool):
        buf += struct.pack("<BB", 2, 1 if val else 0)
    elif isinstance(val, str):
        buf += struct.pack("<B", 1)
        write_string_ref(buf, *strings.add(val))
    elif isinstance(val, int):
        buf += struct.pack("<Bi", 3, val)
    elif isinstance(val, dict) and "ref" in val:
        buf += struct.pack("<B", 4)
        write_string_ref(buf, *strings.add(val["ref"]))
    elif isinstance(val, dict) and "fn" in val:
        buf += struct.pack("<B", 5)
        buf += struct.pack("<B", fn_mapping[val["fn"]])
        args = val.get("argv", [])
        buf += struct.pack("<H", len(args))
        for a in args:
            encode_value(buf, a, strings)
    elif isinstance(val, list):
        buf += struct.pack("<BH", 6, len(val))
        for item in val:
            encode_value(buf, item, strings)
    elif isinstance(val, dict):
        buf += struct.pack("<BH", 7, len(val))
        for k, v in val.items():
            write_string_ref(buf, *strings.add(k))
            encode_value(buf, v, strings)
    else:
        raise ValueError(f"Unsupported value type: {type(val)}")


def encode_parameters(buf, data, strings):
    """Emit parameter count (uint16) then each parameter record."""
    params = data.get("parameters", {})
    buf += struct.pack("<H", len(params))
    for name, p in params.items():
        ptype = p.get("type", "string").lower()
        if ptype == "string":
            opcode = Opcode.PARAM_STRING
        elif ptype == "boolean":
            opcode = Opcode.PARAM_BOOL
        elif ptype == "stringarray":
            opcode = Opcode.PARAM_STRING_ARRAY
        else:
            raise ValueError(f"Unsupported parameter type: {ptype}")
        buf += struct.pack("<B", opcode)
        write_string_ref(buf, *strings.add(name))
        dv = p.get("default")
        has_default = dv is not None
        buf += struct.pack("<B", 1 if has_default else 0)
        if has_default:
            if ptype == "boolean":
                buf += struct.pack("<B", 1 if dv else 0)
            else:
                write_string_ref(buf, *strings.add(str(dv)))
        buf += struct.pack("<B", 1 if p.get("required") else 0)
        built_in = p.get("builtIn")
        buf += struct.pack("<B", 1 if built_in else 0)
        if built_in:
            write_string_ref(buf, *strings.add(built_in))

def encode_conditions(buf, data, strings):
    """Emit condition count (uint16) then each condition record."""
    conditions = data.get("conditions", [])
    buf += struct.pack("<H", len(conditions))
    for c in conditions:
        buf += struct.pack("<B", Opcode.CONDITION)
        buf += struct.pack("<B", fn_mapping[c["fn"]])
        args = c.get("argv", [])
        buf += struct.pack("<H", len(args))
        for a in args:
            encode_value(buf, a, strings)
        assign = c.get("assign")
        buf += struct.pack("<B", 1 if assign else 0)
        if assign:
            write_string_ref(buf, *strings.add(assign))


def encode_results(buf, data, strings):
    """Emit result count (uint16) then each result record."""
    results = data.get("results", [])
    buf += struct.pack("<H", len(results))
    for r in results:
        if "endpoint" in r:
            ep = r["endpoint"]
            buf += struct.pack("<B", Opcode.RESULT_ENDPOINT)
            encode_value(buf, ep.get("url"), strings)
            # Store properties as opaque JSON string
            props = ep.get("properties", {})
            props_json = json.dumps(props, separators=(",", ":")) if props else ""
            write_string_ref(buf, *strings.add(props_json))
            headers = ep.get("headers", {})
            buf += struct.pack("<H", len(headers))
            for name, vs in headers.items():
                write_string_ref(buf, *strings.add(name))
                buf += struct.pack("<H", len(vs))
                for v in vs:
                    encode_value(buf, v, strings)

        elif "error" in r:
            buf += struct.pack("<B", Opcode.RESULT_ERROR)
            encode_value(buf, r["error"], strings)
        else:
            raise ValueError(f"Unsupported result type: {r}")


def encode_nodes(buf, data):
    """Emit root_ref (int32), node_count (uint32), then base64 nodes blob with uint16 length prefix.
    The source JSON has nodes in a base64 blob with big-endian int32s. We re-encode to little-endian."""
    root_ref = data.get("root", 0)
    node_count = data.get("nodeCount", 0)
    buf += struct.pack("<iI", root_ref, node_count)

    nodes_b64 = data.get("nodes", "")
    if not nodes_b64:
        buf += struct.pack("<H", 0)
        return

    raw = base64.b64decode(nodes_b64)
    if len(raw) != node_count * 12:
        raise ValueError(f"Node blob size {len(raw)} != expected {node_count * 12}")
    
    n = len(raw) // 4
    
    # Unpack as big-endian int32, then repack as little-endian int32
    be_values = struct.unpack(f'>{n}i', raw[:n * 4])
    le_bytes = struct.pack(f'<{n}i', *be_values)

    buf += struct.pack("<H", len(le_bytes))

    # Note: on little endian arches we want to be able to index into this array directly
    # but on some platforms with strict alignment (i.e. older arm) the array might be at wrong offset
    # so pad the buffer, so array can start at 4 byte alignment
    padding = (4 - ((len(buf) + 1) % 4)) % 4
    buf += struct.pack("<B", padding)
    buf += b'\x00' * padding

    buf += le_bytes


def encode(data):
    """Single-pass: build all segments in memory, then assemble final bytecode."""
    strings = StringBlob()

    # Build each segment into its own buffer, strings accumulate as we go
    version_buf = bytearray()
    v = data.get("version")
    off, ln = strings.add(v) if v else (0, 0)
    write_string_ref(version_buf, off, ln)

    params_buf = bytearray()
    encode_parameters(params_buf, data, strings)

    conditions_buf = bytearray()
    encode_conditions(conditions_buf, data, strings)

    results_buf = bytearray()
    encode_results(results_buf, data, strings)

    nodes_buf = bytearray()
    encode_nodes(nodes_buf, data)

    # Now assemble: magic + string blob + version + params + conditions + results + nodes
    # Re-encode version ref since blob may have grown after initial version ref was written
    version_buf = bytearray()
    off, ln = strings.add(v) if v else (0, 0)
    write_string_ref(version_buf, off, ln)

    out = bytearray()
    out += struct.pack("<I", MAGIC)
    blob = strings.blob()
    out += struct.pack("<I", len(blob))
    out += blob
    out += version_buf
    out += params_buf
    out += conditions_buf
    out += results_buf
    out += nodes_buf
    return bytes(out)


def verify(bin_path):
    """Read a compiled .bin file and print a human-readable summary."""
    with open(bin_path, "rb") as f:
        data = f.read()
    pos = 0

    def read(fmt):
        nonlocal pos
        size = struct.calcsize(fmt)
        val = struct.unpack_from(fmt, data, pos)
        pos += size
        return val[0] if len(val) == 1 else val

    try:
        magic = read("<I")
        if magic != MAGIC:
            print(f"ERROR: bad magic 0x{magic:08X} (expected 0x{MAGIC:08X})", file=sys.stderr)
            sys.exit(1)

        blob_size = read("<I")
        blob = data[pos:pos + blob_size]
        pos += blob_size

        string_refs = set()

        def track_ref():
            nonlocal pos
            off, ln = struct.unpack_from("<HH", data, pos)
            pos += 4
            if ln > 0:
                string_refs.add((off, ln))

        # Version string ref
        v_off, v_len = read("<HH")
        if v_len > 0:
            string_refs.add((v_off, v_len))
        version_str = blob[v_off:v_off + v_len].decode("ascii") if v_len else ""

        # Parameters
        param_count = read("<H")
        for _ in range(param_count):
            opcode = read("<B")
            track_ref()  # name
            has_def = read("<B")
            if has_def:
                if opcode == Opcode.PARAM_STRING or opcode == Opcode.PARAM_STRING_ARRAY:
                    track_ref()
                else:
                    pos += 1
            pos += 1  # required
            has_bi = read("<B")
            if has_bi:
                track_ref()

        # Conditions
        cond_count = read("<H")

        def skip_value():
            nonlocal pos
            tag = read("<B")
            if tag == 0:
                pass
            elif tag == 1:
                track_ref()
            elif tag == 2:
                pos += 1
            elif tag == 3:
                pos += 4
            elif tag == 4:
                track_ref()
            elif tag == 5:
                track_ref()
                argc = read("<H")
                for _ in range(argc):
                    skip_value()
            elif tag == 6:
                n = read("<H")
                for _ in range(n):
                    skip_value()
            elif tag == 7:
                n = read("<H")
                for _ in range(n):
                    track_ref()
                    skip_value()
            else:
                print(f"ERROR: unknown value tag {tag} at offset {pos}", file=sys.stderr)
                sys.exit(1)

        for _ in range(cond_count):
            pos += 1  # opcode
            track_ref()  # fn ref
            argc = read("<H")
            for _ in range(argc):
                skip_value()
            has_assign = read("<B")
            if has_assign:
                track_ref()

        # Results
        result_count = read("<H")
        for _ in range(result_count):
            opcode = read("<B")
            if opcode == Opcode.RESULT_ENDPOINT:
                track_ref()  # url ref
                track_ref()  # properties json ref
            elif opcode == Opcode.RESULT_ERROR:
                track_ref()  # error ref

        # Nodes
        root_ref, node_count = read("<iI")
        nodes_len = read("<H")
        pos += nodes_len

    except struct.error:
        print(f"ERROR: file truncated at offset {pos}", file=sys.stderr)
        sys.exit(1)

    print(f"Magic:       0x{magic:08X}")
    print(f"Blob size:   {blob_size} bytes")
    print(f"Strings:     {len(string_refs)}")
    print(f"Version:     {version_str!r}")
    print(f"Parameters:  {param_count}")
    print(f"Conditions:  {cond_count}")
    print(f"Results:     {result_count}")
    print(f"Node count:  {node_count}")
    print(f"Root ref:    {root_ref}")
    print(f"Nodes blob:  {nodes_len} bytes (base64)")
    print(f"Total size:  {len(data)} bytes")


def main():
    if "--verify" in sys.argv:
        args = [a for a in sys.argv[1:] if a != "--verify"]
        if not args:
            print(f"Usage: {sys.argv[0]} --verify <file.bin>", file=sys.stderr)
            sys.exit(1)
        verify(args[0])
        return

    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input.json> <output.bin>", file=sys.stderr)
        sys.exit(1)

    input_path, output_path = sys.argv[1], sys.argv[2]

    with open(input_path) as f:
        data = json.load(f)

    bytecode = encode(data)

    with open(output_path, "wb") as f:
        f.write(bytecode)

    print(f"Wrote {len(bytecode)} bytes to {output_path}")


if __name__ == "__main__":
    main()
