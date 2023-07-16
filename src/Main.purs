module Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Options.Applicative (Parser, ParserInfo, argument, execParser, fullDesc, header, helper, info, progDesc, str, (<**>))
import Options.Applicative.Builder (metavar)

data InstallArgs = InstallArgs
  { browser :: String
  , extensionId :: String
  , script :: String
  }

installArgs :: Parser InstallArgs
installArgs = map InstallArgs $ { browser: _, extensionId: _, script: _ }
  <$> argument str (metavar "BROWSER")
  <*> argument str (metavar "EXTENSION_ID")
  <*> argument str (metavar "SCRIPT")

main :: Effect Unit
main = installExtension =<< execParser opts

opts :: ParserInfo InstallArgs
opts = info (installArgs <**> helper)
  ( fullDesc
      <> progDesc "Install an extension for a specific browser"
      <> header "extension install - Extension Installer"
  )

installExtension :: InstallArgs -> Effect Unit
installExtension (InstallArgs { browser, extensionId, script }) =
  log $ "Installing extension " <> extensionId <> " for browser " <> browser
    <> " with script "
    <> show script