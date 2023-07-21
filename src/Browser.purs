module Browser where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.List.NonEmpty (NonEmptyList)
import Data.String (toLower)
import Data.Tuple (Tuple, fst, snd)
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), delay, launchAff_, try)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Foreign (ForeignError)
import Foreign.Object (toUnfoldable)
import Node.ChildProcess (defaultExecSyncOptions, execSync)
import Promise (Promise)
import Promise.Aff (toAffE)
import Simple.JSON (readJSON, unsafeStringify)

import Types (Browser(..), Change, ExtensionInfo, InstallArgs(..), ListenArgs(..), Message, Script)

installExtension :: InstallArgs -> Effect Unit
installExtension (InstallArgs { browser, extensionId, script }) = log $
  "Installing extension " <> extensionId <> " for browser " <> show browser <> " with script " <> show script

listenExtension :: ListenArgs -> Effect Unit
listenExtension (ListenArgs { browser }) = do
  log $ "Listening for changes in extensions for browser " <> show browser
  handleWebSocket handleMessage
  -- https://chromedevtools.github.io/devtools-protocol/#remote
  let
    browserName = case browser of
      Chrome -> "Google Chrome"
      Edge -> "Microsoft Edge"
  let url = toLower $ show browser <> "://extensions/"
  launchAff_ do
    restartBrowser browserName
    extensions <- runInBrowser url getAll unit
    let ids = map _.id extensions
    let urls = map (\id -> "chrome-extension://" <> id <> "/manifest.json") ids
    for_ urls $ \url' -> runInBrowser url' addListener url'
    pure unit

foreign import handleWebSocket :: (String -> Effect Unit) -> Effect Unit

decodeToMessage :: String -> Either (NonEmptyList ForeignError) Message
decodeToMessage = readJSON

handleMessage :: String -> Effect Unit
handleMessage receivedMessage = do
  let decodedMessage = decodeToMessage receivedMessage
  case decodedMessage of
    Left _ -> pure unit
    Right decodedMessage' -> do
      log $ _.url decodedMessage'
      let changeArray = toUnfoldable $ _.changes decodedMessage' :: Array (Tuple String Change)
      for_ changeArray \change -> log $ "chrome.storage." <> _.areaName decodedMessage' <> ".set({" <> fst change <> ": " <> unsafeStringify (_.newValue $ snd change) <> "});"

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

runInBrowser :: forall a b. String -> Script a -> b -> Aff a
runInBrowser url script scriptArg = do
  let endpointURL = "http://localhost:" <> show port
  -- Wait for a second and then retry connecting if the initial attempt to connect fails.
  res <- try $ toAffE $ runInBrowserImpl endpointURL url script scriptArg
  case res of
    Left _ -> do
      delay $ Milliseconds 1000.0
      runInBrowser url script unit
    Right res' -> do
      pure res'

foreign import runInBrowserImpl :: forall a b. String -> String -> Script a -> b -> Effect (Promise a)

foreign import getAll :: Script (Array ExtensionInfo)

foreign import addListener :: Script Unit
