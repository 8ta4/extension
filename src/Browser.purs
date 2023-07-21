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
import Node.FS.Constants (copyFile_FICLONE)
import Node.FS.Perms (all, mkPerms)
import Node.FS.Sync (copyFile', mkdir')
import Node.OS (homedir)
import Promise (Promise)
import Promise.Aff (toAffE)
import Simple.JSON (readJSON, unsafeStringify)
import Types (Browser(..), Change, ExtensionInfo, InstallArgs(..), ListenArgs(..), Message, Script, Options)

installExtension :: InstallArgs -> Effect Unit
installExtension (InstallArgs { browser, extensionId, script }) = do
  log $ "Installing extension " <> extensionId <> " for browser " <> show browser <> " with script " <> show script
  homeDirectory <- homedir
  -- https://developer.chrome.com/docs/extensions/mv3/external_extensions/#preference-mac
  -- https://learn.microsoft.com/en-us/microsoft-edge/extensions-chromium/developer-guide/alternate-distribution-options#using-a-preferences-json-file-macos-and-linux
  let
    extensionDirectory = case browser of
      Chrome -> homeDirectory <> "/Library/Application Support/Google/Chrome/External Extensions"
      Edge -> homeDirectory <> "/Library/Application Support/Microsoft Edge/External Extensions"
  let preferencesFileSourcePath = "preferences/" <> toLower (show browser) <> ".json"
  let preferencesFilePath = extensionDirectory <> "/" <> extensionId <> ".json"
  -- https://github.com/purescript-node/purescript-node-fs/blob/5414a5019bf37a0a2d06514d15c51c61aee33c4a/src/Node/FS/Sync.purs#L234
  -- create directory, if it doesn't exist
  mkdir' extensionDirectory { mode: mkPerms all all all, recursive: true }
  -- copy correct preferences file based on browser
  copyFile' preferencesFileSourcePath preferencesFilePath copyFile_FICLONE

listenExtension :: ListenArgs -> Effect Unit
listenExtension (ListenArgs { browser }) = do
  log $ "Listening for changes in extensions for browser " <> show browser
  handleWebSocket { port: webSocketPort } handleMessage
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
    for_ urls $ \url' -> runInBrowser url' addListener { extension: url', webSocket: "ws://localhost:" <> show webSocketPort }
    pure unit

foreign import handleWebSocket :: Options -> (String -> Effect Unit) -> Effect Unit

webSocketPort :: Int
webSocketPort = 8080

handleMessage :: String -> Effect Unit
handleMessage receivedMessage = do
  let decodedMessage = decodeToMessage receivedMessage
  case decodedMessage of
    Left _ -> pure unit
    Right decodedMessage' -> do
      log $ _.url decodedMessage'
      let changeArray = toUnfoldable $ _.changes decodedMessage' :: Array (Tuple String Change)
      for_ changeArray \change -> log $ "chrome.storage." <> _.areaName decodedMessage' <> ".set({" <> fst change <> ": " <> unsafeStringify (_.newValue $ snd change) <> "});"

decodeToMessage :: String -> Either (NonEmptyList ForeignError) Message
decodeToMessage = readJSON

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
