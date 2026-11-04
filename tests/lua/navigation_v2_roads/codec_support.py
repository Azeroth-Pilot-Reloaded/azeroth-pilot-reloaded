"""Independent test decoder for definite RFC8949 arrays/maps/strings/numbers."""
import io
import struct


def decode(data):
    stream = io.BytesIO(data)
    def item():
        first = stream.read(1)
        if not first:
            raise ValueError('truncated CBOR')
        major, info = first[0] >> 5, first[0] & 31
        if major == 7:
            if info in (20, 21):
                return info == 21
            if info == 27:
                return struct.unpack('>d', stream.read(8))[0]
            raise ValueError('unsupported simple CBOR')
        if info < 24:
            count = info
        else:
            fmt = {24: '>B', 25: '>H', 26: '>I'}[info]
            count = struct.unpack(fmt, stream.read(struct.calcsize(fmt)))[0]
        if major == 0:
            return count
        if major == 1:
            return -1 - count
        if major == 3:
            return stream.read(count).decode('utf-8')
        if major == 4:
            return [item() for _ in range(count)]
        if major == 5:
            return {item(): item() for _ in range(count)}
        raise ValueError('unsupported CBOR major')
    result = item()
    if stream.read():
        raise ValueError('trailing CBOR')
    return result
