module Arkham.Investigator.Cards.JennyBarnes where

import Arkham.Prelude

import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Message

newtype JennyBarnes = JennyBarnes InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

jennyBarnes :: InvestigatorCard JennyBarnes
jennyBarnes = investigator
  JennyBarnes
  Cards.jennyBarnes
  Stats
    { health = 8
    , sanity = 7
    , willpower = 3
    , intellect = 3
    , combat = 3
    , agility = 3
    }

instance HasTokenValue JennyBarnes where
  getTokenValue iid ElderSign (JennyBarnes attrs)
    | iid == investigatorId attrs = pure
    $ TokenValue ElderSign (PositiveModifier $ investigatorResources attrs)
  getTokenValue _ token _ = pure $ TokenValue token mempty

instance RunMessage JennyBarnes where
  runMessage msg (JennyBarnes attrs) = case msg of
    -- TODO: Move this to a modifier
    AllDrawCardAndResource | not (attrs ^. defeatedL || attrs ^. resignedL) ->
      JennyBarnes <$> runMessage msg (attrs & resourcesL +~ 1)
    _ -> JennyBarnes <$> runMessage msg attrs
