module Main where

import Prelude
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log)
import Options.Applicative (Parser, argument, command, execParser, fullDesc, header, helper, info, maybeReader, progDesc, str, subparser, (<**>))
import Options.Applicative.Builder (metavar)
import Options.Applicative.Types (optional)

data Browser = Chrome | Edge

instance showBrowser :: Show Browser where
  show Chrome = "chrome"
  show Edge = "edge"

readBrowser :: String -> Maybe Browser
readBrowser str = case str of
  "chrome" -> Just Chrome
  "edge" -> Just Edge
  _ -> Nothing

data InstallArgs = InstallArgs { browser :: Browser, extensionId :: String, script :: Maybe String }

data ListenArgs = ListenArgs { browser :: Browser }

installArgs :: Parser InstallArgs
installArgs = map InstallArgs $ { browser: _, extensionId: _, script: _ }
  <$> argument (maybeReader readBrowser) (metavar "BROWSER")
  <*> argument str (metavar "EXTENSION_ID")
  <*> optional (argument str (metavar "SCRIPT"))

listenArgs :: Parser ListenArgs
listenArgs = map ListenArgs $ { browser: _ }
  <$> argument (maybeReader readBrowser) (metavar "BROWSER")

data Args = Install InstallArgs | Listen ListenArgs

args :: Parser Args
args = subparser
  ( command "install" (info (Install <$> installArgs) (progDesc "Install an extension for a specific browser"))
      <> command "listen" (info (Listen <$> listenArgs) (progDesc "Listen for changes in extensions for a specific browser"))
  )

main :: Effect Unit
main = do
  argsMain <- execParser (info (args <**> helper) (fullDesc <> header "extension - Extension Manager"))
  case argsMain of
    Install installArgsMain -> installExtension installArgsMain
    Listen listenArgsMain -> listenExtension listenArgsMain

installExtension :: InstallArgs -> Effect Unit
installExtension (InstallArgs { browser, extensionId, script }) = log $
  "Installing extension " <> extensionId <> " for browser " <> (show browser) <> " with script " <> show script

listenExtension :: ListenArgs -> Effect Unit
listenExtension (ListenArgs { browser }) = log $
  "Listening for changes in extensions for browser " <> (show browser)