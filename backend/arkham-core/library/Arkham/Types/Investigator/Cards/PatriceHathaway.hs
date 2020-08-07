{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Investigator.Cards.PatriceHathaway where

import Arkham.Types.Classes
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Message
import Arkham.Types.Stats
import Arkham.Types.Token
import Arkham.Types.Trait
import ClassyPrelude
import Data.Aeson

newtype PatriceHathaway = PatriceHathaway Attrs
  deriving newtype (Show, ToJSON, FromJSON)

patriceHathaway :: PatriceHathaway
patriceHathaway = PatriceHathaway $ baseAttrs
  "06005"
  "Patrice Hathaway"
  Stats
    { health = 7
    , sanity = 7
    , willpower = 4
    , intellect = 2
    , combat = 2
    , agility = 2
    }
  [Performer, Cursed]

instance (InvestigatorRunner env) => RunMessage env PatriceHathaway where
  runMessage msg i@(PatriceHathaway attrs@Attrs {..}) = case msg of
    ResolveToken ElderSign iid _skillValue | iid == investigatorId -> pure i
    _ -> PatriceHathaway <$> runMessage msg attrs
