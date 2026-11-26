"""Check 16 KiB-compatible ELF load segments in packaged native code."""
from struct import unpack_from
from sys import argv
from zipfile import ZipFile


def verify(file_name: str, code: bytes) -> None:
    if code[:6] != b"\x7fELF\x02\x01":
        raise ValueError(f"{file_name}: expected a 64-bit little-endian ELF library")
    table = unpack_from("<Q", code, 32)[0]
    size, count = unpack_from("<HH", code, 54)
    loads = []
    for i in range(count):
        entry = table + size * i
        kind, _, offset, address, _, _, _, alignment = unpack_from("<IIQQQQQQ", code, entry)
        if kind == 1:
            loads.append(alignment)
            if alignment < 16384 or (offset - address) % 16384:
                raise ValueError(f"{file_name}: PT_LOAD supports {alignment} bytes")
    if not loads:
        raise ValueError(f"{file_name}: missing PT_LOAD segments")
    print(f"{file_name}: minimum PT_LOAD alignment {min(loads)} bytes")


with ZipFile(argv[1]) as archive:
    libraries = [name for name in archive.namelist() if "/lib/" in "/" + name and name.endswith(".so")]
    if not libraries:
        raise SystemExit("No shared libraries found in archive")
    for name in libraries:
        verify(name, archive.read(name))
