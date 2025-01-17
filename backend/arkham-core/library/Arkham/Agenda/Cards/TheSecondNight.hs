module Arkham.Agenda.Cards.TheSecondNight
  ( TheSecondNight(..)
  , theSecondNight
  ) where

import Arkham.Prelude

import Arkham.Agenda.Types
import qualified Arkham.Agenda.Cards as Cards
import Arkham.Agenda.Helpers
import Arkham.Agenda.Runner
import Arkham.CampaignLogKey
import Arkham.Card
import Arkham.Classes
import qualified Arkham.Enemy.Cards as Enemies
import Arkham.GameValue
import Arkham.Matcher
import Arkham.Message
import Arkham.Scenarios.APhantomOfTruth.Helpers

newtype TheSecondNight = TheSecondNight AgendaAttrs
  deriving anyclass (IsAgenda, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theSecondNight :: AgendaCard TheSecondNight
theSecondNight = agenda (2, A) TheSecondNight Cards.theSecondNight (Static 5)

instance HasModifiersFor TheSecondNight where
  getModifiersFor target (TheSecondNight a) | not (isTarget a target) = do
    moreConvictionThanDoubt <- getMoreConvictionThanDoubt
    pure $ toModifiers a $ [ DoomSubtracts | moreConvictionThanDoubt ]
  getModifiersFor _ _ = pure []

instance RunMessage TheSecondNight where
  runMessage msg a@(TheSecondNight attrs) = case msg of
    AdvanceAgenda aid | aid == toId attrs && onSide B attrs -> do
      msgs <- disengageEachEnemyAndMoveToConnectingLocation
      pushAll $ msgs <> [NextAdvanceAgendaStep (toId attrs) 2]
      pure a
    NextAdvanceAgendaStep aid 2 | aid == toId attrs && onSide B attrs -> do
      organistMsg <- moveOrganistAwayFromNearestInvestigator
      spawnJordanPerry <- notElem (Recorded $ toCardCode Enemies.jordanPerry)
        <$> getRecordSet VIPsSlain
      card <- genCard Enemies.jordanPerry
      let
        spawnJordanPerryMessages =
          [ CreateEnemyAtLocationMatching
              card
              (LocationWithTitle "Montparnasse")
          | spawnJordanPerry
          ]
      pushAll
        $ organistMsg
        : spawnJordanPerryMessages
        <> [AdvanceAgendaDeck (agendaDeckId attrs) (toSource attrs)]
      pure a
    _ -> TheSecondNight <$> runMessage msg attrs
