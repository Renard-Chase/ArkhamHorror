module Arkham.Action.Additional where

import Arkham.Prelude

import Arkham.Action
import Arkham.Trait

data AdditionalAction
  = TraitRestrictedAdditionalAction Trait
  | ActionRestrictedAdditionalAction Action
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON, Hashable)

