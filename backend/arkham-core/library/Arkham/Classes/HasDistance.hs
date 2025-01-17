module Arkham.Classes.HasDistance where

import Arkham.Prelude

import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Distance
import Arkham.Id

class HasDistance a where
  getDistance' :: (Monad m, HasGame m) => a -> LocationId -> LocationId -> m (Maybe Distance)
