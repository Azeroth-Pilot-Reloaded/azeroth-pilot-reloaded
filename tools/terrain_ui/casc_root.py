"""Check FileDataID registration against an entire build's CASC root index."""

from array import array
from bisect import bisect_left
from struct import iter_unpack, unpack_from


class RootFileIds:
    def __init__(self, data):
        if len(data) < 20:
            raise ValueError("Truncated CASC root header")
        magic, offset, version, total, named = unpack_from("<4s4I", data)
        if magic != b"TSFM" or version not in (1, 2) or not 20 <= offset < len(data) or not 0 <= named <= total:
            raise ValueError("Unsupported CASC root header")
        count = named_count = 0
        self.groups = []
        data = memoryview(data)
        while offset < len(data):
            header_size = 12 if version == 1 else 17
            if len(data) - offset < header_size:
                raise ValueError("Truncated CASC root group header")
            if version == 1:
                entries, flags, _ = unpack_from("<III", data, offset)
            else:
                entries, _, low, high, extra = unpack_from("<4IB", data, offset)
                flags = low | high | (extra << 17)
            offset += header_size
            has_names = not flags & 0x10000000
            end = offset + entries * (28 if has_names else 20)
            if end > len(data) or count + entries > total:
                raise ValueError("Invalid CASC root group size")
            ids = array("I")
            identifier = -1
            for (delta,) in iter_unpack("<I", data[offset:offset + entries * 4]):
                identifier += delta + 1
                if identifier > 0xFFFFFFFF:
                    raise ValueError("CASC FileDataID overflow")
                ids.append(identifier)
            if ids:
                self.groups.append(ids)
            count += entries
            named_count += entries if has_names else 0
            offset = end
        if count != total or named_count != named or not count:
            raise ValueError("Incomplete CASC root index")

    def __contains__(self, identifier):
        for ids in self.groups:
            if ids[0] <= identifier <= ids[-1]:
                position = bisect_left(ids, identifier)
                if position < len(ids) and ids[position] == identifier:
                    return True
        return False
