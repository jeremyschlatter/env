import System.Environment
import System.Exit
import System.Process

main :: IO ()
main = do
  args <- getArgs
  case args of
    (arg:[]) -> callProcess "rg" ["-F", arg]
    _        -> die "usage: rgf <term>"
