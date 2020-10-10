import System.Environment
import System.Exit
import System.Process

main :: IO ()
main = getArgs >>= \case
    arg:[] -> callProcess "rg" ["\\b" <> arg <> "\\b"]
    _      -> die "usage: rgb <term>"
