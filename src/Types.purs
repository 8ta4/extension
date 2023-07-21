module Types where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Data.Show.Generic (genericShow)
import Foreign (Foreign)
import Foreign.Object (Object)

data Args = Install InstallArgs | Listen ListenArgs

data InstallArgs = InstallArgs { browser :: Browser, extensionId :: String, script :: Maybe String }

data ListenArgs = ListenArgs { browser :: Browser }

data Browser = Chrome | Edge

derive instance genericBrowser :: Generic Browser _

instance showBrowser :: Show Browser where
  show = genericShow

data Script :: forall k. k -> Type
data Script a

-- https://developer.chrome.com/docs/extensions/reference/management/#type-ExtensionInfo
type ExtensionInfo = { id :: String }

type Change = { newValue :: Foreign }

type Message = { url :: String, changes :: Object Change, areaName :: String }