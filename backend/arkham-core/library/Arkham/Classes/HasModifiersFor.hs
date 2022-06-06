module Arkham.Classes.HasModifiersFor where

import Arkham.Prelude

import Arkham.Modifier
import Arkham.Source
import Arkham.Target
import {-# SOURCE #-} Arkham.GameEnv

class HasModifiersFor a where
  getModifiersFor :: Source -> Target -> a -> GameT [Modifier]
  getModifiersFor _ _ _ = pure []