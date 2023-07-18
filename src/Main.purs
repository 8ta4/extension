module Main where

import Prelude

import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), delay, launchAff_, try)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Node.ChildProcess (defaultExecSyncOptions, execSync)
import Options.Applicative (Parser, argument, command, execParser, fullDesc, header, helper, info, maybeReader, progDesc, str, subparser, (<**>))
import Options.Applicative.Builder (metavar)
import Options.Applicative.Types (optional)
import Promise (Promise)
import Promise.Aff (toAffE)

data Browser = Chrome | Edge

derive instance genericBrowser :: Generic Browser _

instance showBrowser :: Show Browser where
  show = genericShow

readBrowser :: String -> Maybe Browser
readBrowser str = case str of
  "chrome" -> Just Chrome
  "edge" -> Just Edge
  _ -> Nothing

data InstallArgs = InstallArgs { browser :: Browser, extensionId :: String, script :: Maybe String }

data ListenArgs = ListenArgs { browser :: Browser }

browserArg :: Parser Browser
browserArg = argument (maybeReader readBrowser) (metavar "BROWSER")

installArgs :: Parser InstallArgs
installArgs = map InstallArgs $ { browser: _, extensionId: _, script: _ }
  <$> browserArg
  <*> argument str (metavar "EXTENSION_ID")
  <*> optional (argument str (metavar "SCRIPT"))

listenArgs :: Parser ListenArgs
listenArgs = map ListenArgs $ { browser: _ } <$> browserArg

data Args = Install InstallArgs | Listen ListenArgs

args :: Parser Args
args = subparser
  ( command "install" (info (Install <$> installArgs) (progDesc "Install an extension for a specific browser"))
      <> command "listen" (info (Listen <$> listenArgs) (progDesc "Listen for changes in extensions for a specific browser"))
  )

main :: Effect Unit
main = do
  args' <- execParser (info (args <**> helper) (fullDesc <> header "extension - Extension Manager"))
  case args' of
    Install installArgs' -> installExtension installArgs'
    Listen listenArgs' -> listenExtension listenArgs'

installExtension :: InstallArgs -> Effect Unit
installExtension (InstallArgs { browser, extensionId, script }) = log $
  "Installing extension " <> extensionId <> " for browser " <> show browser <> " with script " <> show script

port :: Int
port = 9222

isBrowserRunning :: String -> Effect Boolean
isBrowserRunning browserName = do
  let command = "pgrep -x '" <> browserName <> "'"
  -- pgrep returns an error if it doesn't find any process matching the criteria
  -- Catch the error and return False indicating that the browser is not running
  result <- try $ execSync command defaultExecSyncOptions
  case result of
    Left _ -> pure false
    Right _ -> pure true

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
    runInBrowser url getAllImpl

foreign import getAllImpl :: Effect Unit

runCommand :: String -> Effect Unit
runCommand command = do
  _ <- execSync command defaultExecSyncOptions
  pure unit

quitBrowser :: String -> Effect Unit
quitBrowser browserName = do
  let command = "osascript -e 'quit app \"" <> browserName <> "\"'"
  runCommand command

openBrowser :: String -> Effect Unit
openBrowser browserName = do
  let command = "open -a '" <> browserName <> "' --args --remote-debugging-port=" <> show port
  runCommand command

waitForBrowserToClose :: String -> Aff Unit
waitForBrowserToClose browserName = do
  running <- liftEffect $ isBrowserRunning browserName
  when running do
    delay $ Milliseconds 1000.0
    waitForBrowserToClose browserName

restartBrowser :: String -> Aff Unit
restartBrowser browserName = do
  running <- liftEffect $ isBrowserRunning browserName
  when running do
    liftEffect $ quitBrowser browserName
    waitForBrowserToClose browserName
  liftEffect $ openBrowser browserName

foreign import runInBrowserImpl :: forall a. String -> String -> Effect Unit -> Effect (Promise a)

runInBrowser :: forall a. String -> Effect Unit -> Aff a
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