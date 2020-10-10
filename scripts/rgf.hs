import System.Environment
import System.Exit
import System.Process

main :: IO ()
main = getArgs >>= \case
  arg:[] -> callProcess "rg" ["-F", arg]
  _      -> die "usage: rgf <term>"
