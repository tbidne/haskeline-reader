module Main where

import System.Console.Haskeline
import System.Environment

{--
Testing the line-input functions and their interaction with ctrl-c signals.

Usage:
./Test          (line input)
./Test chars    (character input)
./Test password (no masking characters)
./Test password \*
./Test initial  (use initial text in the prompt)
--}

mySettings :: Settings IO
mySettings = defaultSettings {historyFile = Just "myhist"}

main :: IO ()
main = do
  args <- getArgs
  let inputFunc = case args of
        ["chars"] -> fmap (fmap (: [])) . getInputChar
        ["password"] -> getPassword Nothing
        ["password", [c]] -> getPassword (Just c)
        ["initial"] -> flip getInputLineWithInitial ("left ", "right")
        _ -> getInputLine
  runInputT mySettings $ withInterrupt $ loop inputFunc 0
  where
    loop :: (String -> InputT IO (Maybe String)) -> Int -> InputT IO ()
    loop inputFunc n = do
      minput <-
        handleInterrupt (return (Just "Caught interrupted")) $
          inputFunc (show n ++ ":")
      case minput of
        Nothing -> return ()
        Just "quit" -> return ()
        Just "q" -> return ()
        Just s -> do
          outputStrLn ("line " ++ show n ++ ":" ++ s)
          loop inputFunc (n + 1)
