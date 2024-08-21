module Browser where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), delay, try)
import Effect.Class (liftEffect)
import Node.ChildProcess (defaultExecSyncOptions, execSync)
import Promise (Promise)
import Promise.Aff (toAffE)
import Types (Browser(..), PlaywrightBrowser, PlaywrightPage, Script)

getBrowserName :: Browser -> String
getBrowserName browser =
  case browser of
    Arc -> "Arc"
    Chrome -> "Google Chrome"
    Edge -> "Microsoft Edge"

restartBrowser :: Browser -> Aff Unit
restartBrowser browser = do
  running <- liftEffect $ isBrowserRunning browser
  when running do
    liftEffect $ quitBrowser browser
    waitForBrowserToClose browser
  liftEffect $ openBrowser browser

isBrowserRunning :: Browser -> Effect Boolean
isBrowserRunning browser = do
  let command = "pgrep -x '" <> getBrowserName browser <> "'"
  -- pgrep returns an error if it doesn't find any process matching the criteria
  -- Catch the error and return False indicating that the browser is not running
  result <- try $ execSync command defaultExecSyncOptions
  case result of
    Left _ -> pure false
    Right _ -> pure true

quitBrowser :: Browser -> Effect Unit
quitBrowser browser = do
  let command = "osascript -e 'quit app \"" <> getBrowserName browser <> "\"'"
  runCommand command

runCommand :: String -> Effect Unit
runCommand command = do
  -- The execSync command is wrapped in a try block to handle any errors that might occur when running the command.
  -- This change was made to handle errors like "Google Chrome got an error: User canceled. (-128)" that were causing the program to crash.
  -- This error occurred when Chrome was freshly installed and hadn't been set up yet.
  -- Now, if an error occurs, it will be caught and handled by the try block, preventing the program from crashing.
  _ <- try $ execSync command defaultExecSyncOptions
  pure unit

waitForBrowserToClose :: Browser -> Aff Unit
waitForBrowserToClose browser = do
  running <- liftEffect $ isBrowserRunning browser
  when running do
    delay $ Milliseconds 1000.0
    waitForBrowserToClose browser

openBrowser :: Browser -> Effect Unit
openBrowser browser = do
  let
    command = "open -a '" <> getBrowserName browser
      <> "' --args --remote-debugging-port="
      <> show remoteDebuggingPort
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
