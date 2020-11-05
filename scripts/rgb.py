from subprocess import *
from sys import *

if len(argv) != 2:
  print('usage: rgb <term>', file=stderr)
  exit(1)

exit(run(['rg', fr'\b{argv[1]}\b']).returncode)
