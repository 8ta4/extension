module Browser where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), delay, try)
import Effect.Class (liftEffect)
import Node.ChildProcess (defaultExecSyncOptions, execSync)

restartBrowser :: String -> Aff Unit
restartBrowser browserName = do
  running <- liftEffect $ isBrowserRunning browserName
  when running do
    liftEffect $ quitBrowser browserName
    waitForBrowserToClose browserName
  liftEffect $ openBrowser browserName

isBrowserRunning :: String -> Effect Boolean
isBrowserRunning browserName = do
  let command = "pgrep -x '" <> browserName <> "'"
  -- pgrep returns an error if it doesn't find any process matching the criteria
  -- Catch the error and return False indicating that the browser is not running
  result <- try $ execSync command defaultExecSyncOptions
  case result of
    Left _ -> pure false
    Right _ -> pure true

quitBrowser :: String -> Effect Unit
quitBrowser browserName = do
  let command = "osascript -e 'quit app \"" <> browserName <> "\"'"
  runCommand command

runCommand :: String -> Effect Unit
runCommand command = do
  _ <- execSync command defaultExecSyncOptions
  pure unit

waitForBrowserToClose :: String -> Aff Unit
waitForBrowserToClose browserName = do
  running <- liftEffect $ isBrowserRunning browserName
  when running do
    delay $ Milliseconds 1000.0
    waitForBrowserToClose browserName

openBrowser :: String -> Effect Unit
openBrowser browserName = do
  let command = "open -a '" <> browserName <> "' --args --remote-debugging-port=" <> show remoteDebuggingPort
  runCommand command

remoteDebuggingPort :: Int
remoteDebuggingPort = 9222
