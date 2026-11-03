"""Independent RFC 8949 subset reader for test callbacks (not addon code)."""
import io
import struct


def decode(data):
    stream = io.BytesIO(data)

    def item():
        initial = stream.read(1)
        if not initial:
            raise ValueError('truncated_cbor')
        major, extra = initial[0] >> 5, initial[0] & 31
        if extra < 24:
            count = extra
        else:
            fmt = {24:'>B',25:'>H',26:'>I'}[extra]
            count = struct.unpack(fmt, stream.read(struct.calcsize(fmt)))[0]
        if major == 4:
            return [item() for _ in range(count)]
        if major == 0:
            return count
        if major == 1:
            return -1-count
        raise ValueError('unsupported_cbor')

    value = item()
    if stream.read():
        raise ValueError('trailing_cbor')
    return value
