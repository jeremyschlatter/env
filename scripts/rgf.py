from subprocess import *
from sys import *

if len(argv) != 2:
  print('usage: rgf <term>', file=stderr)
  exit(1)

exit(run(['rg', '-F', argv[1]]).returncode)
