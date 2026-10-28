import os
import shutil
import sys

LARGE_ADDRESS_AWARE = 0x0020


def fail(msg):
    print(f"wow-large-address-aware: error: {msg}", file=sys.stderr)
    sys.exit(1)


def main():
    if len(sys.argv) != 2:
        fail("usage: wow-large-address-aware <path-to-exe>")

    path = sys.argv[1]
    if not os.path.isfile(path):
        fail(f"not a file: {path}")

    with open(path, "rb") as f:
        if f.read(2) != b"MZ":
            fail(f"not a PE executable: {path}")
        f.seek(0x3C)
        e_lfanew = int.from_bytes(f.read(4), "little")
        f.seek(e_lfanew)
        signature = f.read(4)
        if signature[:2] != b"PE" or signature[2:] != bytes(2):
            fail(f"not a PE executable: {path}")
        offset = e_lfanew + 22
        f.seek(offset)
        characteristics = int.from_bytes(f.read(2), "little")

    if characteristics & LARGE_ADDRESS_AWARE:
        print(f"wow-large-address-aware: {path} is already Large Address Aware")
        return

    backup = path + ".bckp"
    if not os.path.exists(backup):
        shutil.copy2(path, backup)
        print(f"wow-large-address-aware: created backup {backup}")

    with open(path, "r+b") as f:
        f.seek(offset)
        f.write((characteristics | LARGE_ADDRESS_AWARE).to_bytes(2, "little"))

    print(f"wow-large-address-aware: enabled Large Address Aware on {path}")


if __name__ == "__main__":
    main()
