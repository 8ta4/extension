module Main where

import Prelude
import Data.Maybe (Maybe)
import Effect (Effect)
import Effect.Console (log)
import Options.Applicative (Parser, argument, command, execParser, fullDesc, header, helper, info, progDesc, str, subparser, (<**>))
import Options.Applicative.Builder (metavar)
import Options.Applicative.Types (optional)

data InstallArgs = InstallArgs { browser :: String, extensionId :: String, script :: Maybe String }
data ListenArgs = ListenArgs { browser :: String }

installArgs :: Parser InstallArgs
installArgs = map InstallArgs $ { browser: _, extensionId: _, script: _ }
  <$> argument str (metavar "BROWSER")
  <*> argument str (metavar "EXTENSION_ID")
  <*> (optional $ argument str (metavar "SCRIPT"))

listenArgs :: Parser ListenArgs
listenArgs = map ListenArgs $ { browser: _ }
  <$> argument str (metavar "BROWSER")

data Args = Install InstallArgs | Listen ListenArgs

args :: Parser Args
args = subparser
  ( command "install" (info (Install <$> installArgs) (progDesc "Install an extension for a specific browser"))
  <> command "listen" (info (Listen <$> listenArgs) (progDesc "Listen for changes in extensions for a specific browser"))
  )

main :: Effect Unit
main = do
  args <- execParser (info (args <**> helper) (fullDesc <> header "extension - Extension Manager"))
  case args of
    Install installArgs -> installExtension installArgs
    Listen listenArgs -> listenExtension listenArgs

installExtension :: InstallArgs -> Effect Unit
installExtension (InstallArgs { browser, extensionId, script }) = log $
  "Installing extension " <> extensionId <> " for browser " <> browser <> " with script " <> show script

listenExtension :: ListenArgs -> Effect Unit
listenExtension (ListenArgs { browser }) = log $
  "Listening for changes in extensions for browser " <> browser