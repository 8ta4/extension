module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Options.Applicative (Parser, argument, command, execParser, fullDesc, header, helper, info, maybeReader, progDesc, str, subparser, (<**>))
import Options.Applicative.Builder (metavar)
import Options.Applicative.Types (optional)

import Browser (installExtension, listenExtension)
import Types (Args(..), Browser(..), InstallArgs(..), ListenArgs(..))

main :: Effect Unit
main = do
  args' <- execParser (info (args <**> helper) (fullDesc <> header "extension - Extension Manager"))
  case args' of
    Install installArgs' -> installExtension installArgs'
    Listen listenArgs' -> listenExtension listenArgs'

args :: Parser Args
args = subparser
  ( command "install" (info (Install <$> installArgs) (progDesc "Install an extension for a specific browser"))
      <> command "listen" (info (Listen <$> listenArgs) (progDesc "Listen for changes in extensions for a specific browser"))
  )

installArgs :: Parser InstallArgs
installArgs = map InstallArgs $ { browser: _, extensionId: _, script: _ }
  <$> browserArg
  <*> argument str (metavar "EXTENSION_ID")
  <*> optional (argument str (metavar "SCRIPT"))

browserArg :: Parser Browser
browserArg = argument (maybeReader readBrowser) (metavar "BROWSER")

readBrowser :: String -> Maybe Browser
readBrowser str = case str of
  "chrome" -> Just Chrome
  "edge" -> Just Edge
  _ -> Nothing

listenArgs :: Parser ListenArgs
listenArgs = map ListenArgs $ { browser: _ } <$> browserArg
