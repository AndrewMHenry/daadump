"""Extract table from DAATable.8Xv."""
import json


TABLE_OFFSET = 0x004a
TABLE_LENGTH = 0x1000


def extract_table(appvar):
    """Return table bytes from appvar file."""
    with open(appvar, 'rb') as f:
        contents = f.read()

    return contents[TABLE_OFFSET:TABLE_OFFSET+TABLE_LENGTH]


def pack_words(contents):
    """Given table contents as bytes, return list of 16-bit words as ints."""
    return [contents[i] + (contents[i + 1] << 8)
            for i in range(0, len(contents), 2)]


def to_json(filename, contents):
    """Write JSON representation of contents to file named filename."""
    with open(filename, 'w') as f:
        f.write(json.dumps(list(contents)))


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('appvar')
    parser.add_argument('outfile')
    args = parser.parse_args()

    to_json(args.outfile, pack_words(extract_table(args.appvar)))

