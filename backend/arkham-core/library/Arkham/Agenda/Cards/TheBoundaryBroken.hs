module Arkham.Agenda.Cards.TheBoundaryBroken
  ( TheBoundaryBroken(..)
  , theBoundaryBroken
  ) where

import Arkham.Prelude

import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Runner
import Arkham.CampaignLogKey
import Arkham.Card
import Arkham.Classes
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.GameValue
import Arkham.Helpers.Investigator
import Arkham.Helpers.Log
import Arkham.Helpers.Query
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype TheBoundaryBroken = TheBoundaryBroken AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theBoundaryBroken :: AgendaCard TheBoundaryBroken
theBoundaryBroken =
  agenda (1, A) TheBoundaryBroken Cards.theBoundaryBroken (Static 8)

instance RunMessage TheBoundaryBroken where
  runMessage msg a@(TheBoundaryBroken attrs) = case msg of
    AdvanceAgenda aid | aid == toId attrs && onSide B attrs -> do
      harbingerAlive <- getHasRecord TheHarbingerIsStillAlive
      yigsFury <- getRecordCount YigsFury
      harbinger <- genCard Enemies.harbingerOfValusia
      locationId <- if yigsFury >= 6
        then getJustLocation =<< getLeadInvestigatorId
        else selectJust $ FarthestLocationFromAll Anywhere
      pushAll
        $ [ CreateEnemyAt harbinger locationId (Just $ toTarget attrs)
          | harbingerAlive
          ]
        <> [AdvanceAgendaDeck (agendaDeckId attrs) (toSource attrs)]
      pure a
    CreatedEnemyAt harbingerId _ (isTarget attrs -> True) -> do
      startingDamage <- getRecordCount TheHarbingerIsStillAlive
      when (startingDamage > 0) $ push $ PlaceDamage
        (EnemyTarget harbingerId)
        startingDamage
      pure a
    _ -> TheBoundaryBroken <$> runMessage msg attrs
