{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Investigator.Cards.UrsulaDowns where

import Arkham.Types.Classes
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Message
import Arkham.Types.Stats
import Arkham.Types.Token
import Arkham.Types.Trait
import ClassyPrelude
import Data.Aeson

newtype UrsulaDowns = UrsulaDowns Attrs
  deriving newtype (Show, ToJSON, FromJSON)

ursulaDowns :: UrsulaDowns
ursulaDowns = UrsulaDowns $ baseAttrs
  "04002"
  "Ursula Downs"
  Stats
    { health = 7
    , sanity = 7
    , willpower = 3
    , intellect = 4
    , combat = 1
    , agility = 4
    }
  [Wayfarer]

instance (InvestigatorRunner env) => RunMessage env UrsulaDowns where
  runMessage msg i@(UrsulaDowns attrs@Attrs {..}) = case msg of
    ResolveToken ElderSign iid _skillValue | iid == investigatorId -> pure i
    _ -> UrsulaDowns <$> runMessage msg attrs
