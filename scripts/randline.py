"""Usage: randline FILE [COUNT] [FILE2 [COUNT2] ...]

Prints a random line from FILE.

If a numeric COUNT is given, print COUNT random lines from FILE.
If multiple FILEs are given, print random random line(s) from each.
All lines in the output are whitespace-trimmed and space-separated.
"""
from sys import argv
from random import choice

try:
    arr = []
    i = 1
    while i < len(argv):
        filename = argv[i]
        if i+1 < len(argv) and argv[i+1].isnumeric():
            count = int(argv[i+1])
            i += 2
        else:
            count = 1
            i += 1
        with open(filename) as f:
            lines = f.readlines()
            for _ in range(count):
                arr.append(choice(lines).strip())

    print(" ".join(arr))
except Exception:
    print(__doc__)
    print()
