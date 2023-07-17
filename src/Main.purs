module Main where

import Prelude

import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), delay, launchAff_, try)
import Effect.Console (log)
import Node.ChildProcess (defaultSpawnOptions, spawn)
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

listenExtension :: ListenArgs -> Effect Unit
listenExtension (ListenArgs { browser }) = do
  log $ "Listening for changes in extensions for browser " <> show browser
  let browserName = case browser of
                        Chrome -> "Google Chrome"
                        Edge -> "Microsoft Edge"
  let command = "open"
  let args' = ["-a", browserName, "--args", "--remote-debugging-port=" <> show port]
  runCommand command args'
  launchAff_ $ runInBrowser

foreign import runInBrowserImpl :: forall a. String -> Effect (Promise a)

runCommand :: String -> Array String -> Effect Unit
runCommand command args' = do
  _ <- spawn command args' defaultSpawnOptions
  pure unit

runInBrowser :: Aff Unit
runInBrowser = do
  let endpointURL = "http://localhost:" <> show port
-- This approach ensures that your code will wait for a second and then retry connecting if the initial attempt to connect fails.
  res <- try $ toAffE $ runInBrowserImpl endpointURL
  case res of
    Left _ -> do
      delay $ Milliseconds 1000.0
      runInBrowser
    Right _ -> do
      pure unit