module System.Console.Haskeline.Emacs where

import System.Console.Haskeline.Command
import System.Console.Haskeline.Command.Completion
import System.Console.Haskeline.Command.History
import System.Console.Haskeline.LineState
import System.Console.Haskeline.InputT

import Data.Char

type InputCmd s t = forall m . Monad m => Command (InputCmdT m) s t

emacsCommands :: Monad m => KeyMap (InputCmdT m) InsertMode
emacsCommands = runCommand $ choiceCmd [simpleActions, controlActions]

simpleActions, controlActions :: InputCmd InsertMode InsertMode
simpleActions = choiceCmd 
            [ KeyChar '\n' +> finish
	    , KeyChar '\r' +> finish
            , KeyLeft +> change goLeft
            , KeyRight +> change goRight
            , Backspace +> change deletePrev
            , KeyChar '\b' +> change deletePrev
	    , DeleteForward +> change deleteNext 
            , changeFromChar insertChar
            , KeyChar '\t' +> completionCmd
            , KeyUp +> historyBack
            , KeyDown +> historyForward
            , searchHistory
            ] 
            
controlActions = choiceCmd
            [ controlKey 'a' +> change moveToStart 
            , controlKey 'e' +> change moveToEnd
            , controlKey 'b' +> change goLeft
            , controlKey 'c' +> change goRight
            , controlKey 'd' +> deleteCharOrEOF
            , controlKey 'l' +> clearScreenCmd
            , KeyMeta 'f' +> change wordRight
            , KeyMeta 'b' +> change wordLeft
            , controlKey 'w' +> change (deleteFromMove bigWordLeft)
            -- TODO: M-DELETE +> change (deleteFromMove wordLeft)
            , KeyMeta 'd' +> change (deleteFromMove wordRight)
            , controlKey 'k' +> change (deleteFromMove moveToEnd)
            ]

deleteCharOrEOF :: Key -> InputCmd InsertMode InsertMode
deleteCharOrEOF k = k +> acceptKeyOrFail (\s -> if s == emptyIM
            then Nothing
            else Just $ Change (deleteNext s) >=> justDelete)
    where
        justDelete = try (change deleteNext k >|> justDelete)

wordRight, wordLeft, bigWordLeft :: InsertMode -> InsertMode
wordRight = skipRight isAlphaNum . skipRight (not . isAlphaNum)
wordLeft = skipLeft isAlphaNum . skipLeft (not . isAlphaNum)
bigWordLeft = skipLeft (not . isSpace) . skipLeft isSpace
