"""Package the checked kit and its exact release binaries into a reproducible ZIP."""

from argparse import ArgumentParser
import hashlib
from pathlib import Path
from shutil import copyfileobj
from zipfile import ZIP_STORED, ZipFile, ZipInfo


def archive(kit, artifacts, output):
    files = {path.relative_to(kit): path for path in kit.rglob("*") if path.is_file()}
    checksums = kit / "01_AAB/SHA256SUMS.txt"
    for line in checksums.read_text(encoding="utf-8").splitlines():
        digest, name = line.split()
        if Path(name).name != name or Path(name).suffix not in {".apk", ".aab"}:
            raise ValueError(f"unexpected artifact name: {name}")
        file = artifacts / name
        with file.open("rb") as stream:
            if hashlib.file_digest(stream, "sha256").hexdigest() != digest:
                raise ValueError(f"artifact does not match SHA-256: {name}")
        files[Path("01_AAB") / name] = file
    output.parent.mkdir(parents=True, exist_ok=True)
    staging = output.with_suffix(".zip.partial")
    try:
        with ZipFile(staging, "w", compression=ZIP_STORED) as out:
            for relative, path in sorted(files.items(), key=lambda entry: entry[0].as_posix()):
                if path.is_symlink() or path.suffix in {".p12", ".jks", ".keystore", ".pem", ".env"}:
                    raise ValueError(f"unexpected file: {path.name}")
                member = ZipInfo(f"GOOGLE_PLAY_READY/{relative.as_posix()}", (2026, 11, 27, 0, 0, 0))
                member.create_system = 3
                member.external_attr = 0o100644 << 16
                member.file_size = path.stat().st_size
                with path.open("rb") as source, out.open(member, "w") as target:
                    copyfileobj(source, target, length=1024 * 1024)
        staging.replace(output)
    finally:
        staging.unlink(missing_ok=True)
    with output.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    print(f"{digest}  {output} ({len(files)} files; {output.stat().st_size} bytes)")


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("kit", type=Path)
    parser.add_argument("artifacts", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    archive(args.kit, args.artifacts, args.output)


if __name__ == "__main__":
    main()
