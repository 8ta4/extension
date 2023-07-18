module Browser where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), delay, launchAff_, try)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Node.ChildProcess (defaultExecSyncOptions, execSync)
import Promise (Promise)
import Promise.Aff (toAffE)
import Types (Browser(..), ExtensionInfo, InstallArgs(..), ListenArgs(..))

installExtension :: InstallArgs -> Effect Unit
installExtension (InstallArgs { browser, extensionId, script }) = log $
  "Installing extension " <> extensionId <> " for browser " <> show browser <> " with script " <> show script

listenExtension :: ListenArgs -> Effect Unit
listenExtension (ListenArgs { browser }) = do
  log $ "Listening for changes in extensions for browser " <> show browser
  -- https://chromedevtools.github.io/devtools-protocol/#remote
  let
    browserName = case browser of
      Chrome -> "Google Chrome"
      Edge -> "Microsoft Edge"
  let url = show browser <> "://extensions/"
  launchAff_ do
    restartBrowser browserName
    extensions <- runInBrowser url getAllImpl
    let ids = map _.id extensions
    let _ = map (\id -> "chrome-extension://" <> id <> "/manifest.json") ids
    pure unit

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
  let command = "open -a '" <> browserName <> "' --args --remote-debugging-port=" <> show port
  runCommand command

port :: Int
port = 9222

runInBrowser :: forall a. String -> Aff a -> Aff a
runInBrowser url script = do
  let endpointURL = "http://localhost:" <> show port
  -- Wait for a second and then retry connecting if the initial attempt to connect fails.
  -- toAffE $ runInBrowserImpl endpointURL url
  res <- try $ toAffE $ runInBrowserImpl endpointURL url script
  case res of
    Left _ -> do
      delay $ Milliseconds 1000.0
      runInBrowser url script
    Right res' -> do
      pure res'

foreign import runInBrowserImpl :: forall a. String -> String -> Aff a -> Effect (Promise a)

foreign import getAllImpl :: Aff (Array ExtensionInfo)
