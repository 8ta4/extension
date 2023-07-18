module Main where

import Prelude

import Browser (installExtension, listenExtension)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Options.Applicative (Parser, argument, command, execParser, fullDesc, header, helper, info, maybeReader, progDesc, str, subparser, (<**>))
import Options.Applicative.Builder (metavar)
import Options.Applicative.Types (optional)
import Types (Args(..), Browser(..), InstallArgs(..), ListenArgs(..))

readBrowser :: String -> Maybe Browser
readBrowser str = case str of
  "chrome" -> Just Chrome
  "edge" -> Just Edge
  _ -> Nothing

browserArg :: Parser Browser
browserArg = argument (maybeReader readBrowser) (metavar "BROWSER")

installArgs :: Parser InstallArgs
installArgs = map InstallArgs $ { browser: _, extensionId: _, script: _ }
  <$> browserArg
  <*> argument str (metavar "EXTENSION_ID")
  <*> optional (argument str (metavar "SCRIPT"))

listenArgs :: Parser ListenArgs
listenArgs = map ListenArgs $ { browser: _ } <$> browserArg

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
