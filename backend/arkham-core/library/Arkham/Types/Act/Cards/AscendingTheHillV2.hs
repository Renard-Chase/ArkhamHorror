module Arkham.Types.Act.Cards.AscendingTheHillV2
  ( AscendingTheHillV2(..)
  , ascendingTheHillV2
  ) where

import Arkham.Prelude

import Arkham.EncounterCard
import Arkham.Types.Act.Attrs
import Arkham.Types.Act.Runner
import Arkham.Types.ActId
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Target
import Arkham.Types.Trait

newtype AscendingTheHillV2 = AscendingTheHillV2 ActAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ascendingTheHillV2 :: AscendingTheHillV2
ascendingTheHillV2 = AscendingTheHillV2
  $ baseAttrs "02279" "Ascending the Hill (v. II)" (Act 2 A) Nothing

instance HasSet Trait env LocationId => HasModifiersFor env AscendingTheHillV2 where
  getModifiersFor _ (LocationTarget lid) (AscendingTheHillV2 attrs) = do
    traits <- getSet lid
    pure $ toModifiers attrs [ CannotPlaceClues | Altered `notMember` traits ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env AscendingTheHillV2 where
  getActions i window (AscendingTheHillV2 x) = getActions i window x

instance (HasName env LocationId, ActRunner env) => RunMessage env AscendingTheHillV2 where
  runMessage msg a@(AscendingTheHillV2 attrs@ActAttrs {..}) = case msg of
    AdvanceAct aid _ | aid == actId && onSide A attrs -> do
      leadInvestigatorId <- getLeadInvestigatorId
      unshiftMessage
        $ chooseOne leadInvestigatorId [AdvanceAct aid (toSource attrs)]
      pure
        . AscendingTheHillV2
        $ attrs
        & (sequenceL .~ Act (unActStep $ actStep actSequence) B)
    AdvanceAct aid _ | aid == actId && onSide B attrs -> do
      sentinelPeak <- fromJustNote "must exist"
        <$> getLocationIdWithTitle "Sentinel Peak"
      sethBishop <- EncounterCard <$> genEncounterCard "02293"
      a <$ unshiftMessages
        [CreateEnemyAt sethBishop sentinelPeak Nothing, NextAct actId "02281"]
    WhenEnterLocation _ lid -> do
      name <- getName lid
      a <$ when
        (name == "Sentinel Hill")
        (unshiftMessage $ AdvanceAct actId (toSource attrs))
    _ -> AscendingTheHillV2 <$> runMessage msg attrs