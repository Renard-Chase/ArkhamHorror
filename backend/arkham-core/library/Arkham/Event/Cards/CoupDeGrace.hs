module Arkham.Event.Cards.CoupDeGrace
  ( coupDeGrace
  , CoupDeGrace(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.DamageEffect
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Game.Helpers
import Arkham.Matcher hiding ( EnemyDefeated, NonAttackDamageEffect )
import Arkham.Message

newtype CoupDeGrace = CoupDeGrace EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

coupDeGrace :: EventCard CoupDeGrace
coupDeGrace = event CoupDeGrace Cards.coupDeGrace

instance RunMessage CoupDeGrace where
  runMessage msg e@(CoupDeGrace attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      isTurn <- iid <=~> TurnInvestigator
      enemies <-
        selectList
        $ EnemyAt (locationWithInvestigator iid)
        <> EnemyCanBeDamagedBySource (toSource attrs)
      pushAll
        $ chooseOrRunOne
            iid
            [ targetLabel
                enemy
                [EnemyDamage enemy iid (toSource attrs) NonAttackDamageEffect 1]
            | enemy <- enemies
            ]
        : [ ChooseEndTurn iid | isTurn ]
        <> [Discard (toTarget attrs)]
      pure e
    EnemyDefeated _ iid _ (isSource attrs -> True) _ -> do
      push $ DrawCards iid 1 False
      pure e
    _ -> CoupDeGrace <$> runMessage msg attrs