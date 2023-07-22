module Browser where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), delay, try)
import Effect.Class (liftEffect)
import Node.ChildProcess (defaultExecSyncOptions, execSync)
import Promise (Promise)
import Promise.Aff (toAffE)
import Types (PlaywrightBrowser, PlaywrightPage, Script)

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

runInBrowser :: forall a b. String -> Script a -> b -> Aff a
runInBrowser url script scriptArg = do
  let endpointURL = "http://localhost:" <> show remoteDebuggingPort
  browser <- connectOverCDP endpointURL
  page <- toAffE $ newPage browser url
  res <- evaluate page script scriptArg
  _ <- toAffE $ close browser
  pure res

tryRetry :: forall a. Aff a -> Aff a
tryRetry action = do
  result <- try action
  case result of
    Left _ -> do
      delay $ Milliseconds 1000.0
      tryRetry action
    Right value -> pure value

connectOverCDP :: String -> Aff PlaywrightBrowser
connectOverCDP endpointURL =
  let
    action = toAffE $ connectOverCDPImpl endpointURL
  in
    tryRetry action

foreign import connectOverCDPImpl :: String -> Effect (Promise PlaywrightBrowser)

foreign import newPage :: PlaywrightBrowser -> String -> Effect (Promise PlaywrightPage)

evaluate :: forall a b. PlaywrightPage -> Script a -> b -> Aff a
evaluate page script scriptArg =
  let
    action = toAffE $ evaluateImpl page script scriptArg
  in
    tryRetry action

foreign import evaluateImpl :: forall a b. PlaywrightPage -> Script a -> b -> Effect (Promise a)

foreign import close :: PlaywrightBrowser -> Effect (Promise Unit)
