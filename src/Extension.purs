module Extension where

import Prelude

import Browser (restartBrowser, runInBrowser)
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.List.NonEmpty (NonEmptyList)
import Data.String (toLower)
import Data.Tuple (Tuple, fst, snd)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Console (log)
import Foreign (ForeignError)
import Foreign.Object (toUnfoldable)
import Node.FS.Constants (copyFile_FICLONE)
import Node.FS.Perms (all, mkPerms)
import Node.FS.Sync (copyFile', mkdir')
import Node.OS (homedir)
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
  launchAff_ do
    restartBrowser browser
    runInBrowser (extensionUrl browser) enableExtension extensionId

extensionUrl :: Browser -> String
extensionUrl browser = toLower $ show browser <> "://extensions/"

foreign import enableExtension :: Script Unit

listenExtension :: ListenArgs -> Effect Unit
listenExtension (ListenArgs { browser }) = do
  log $ "Listening for changes in extensions for browser " <> show browser
  handleWebSocket { port: webSocketPort } handleMessage
  -- https://chromedevtools.github.io/devtools-protocol/#remote
  launchAff_ do
    restartBrowser browser
    extensions <- runInBrowser (extensionUrl browser) getAll unit
    let ids = map _.id extensions
    let urls = map (\id -> "chrome-extension://" <> id <> "/manifest.json") ids
    for_ urls $ \url -> runInBrowser url addListener { extension: url, webSocket: "ws://localhost:" <> show webSocketPort }

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

foreign import getAll :: Script (Array ExtensionInfo)

foreign import addListener :: Script Unit
