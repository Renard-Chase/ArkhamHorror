module Arkham.Enemy.Cards.BogGator
  ( bogGator
  , BogGator(..)
  ) where

import Arkham.Prelude

import Arkham.Enemy.Cards qualified as Cards
import Arkham.Classes
import Arkham.Enemy.Runner
import Arkham.Id
import Arkham.Modifier
import Arkham.Prey
import Arkham.SkillType
import Arkham.Target
import Arkham.Trait

newtype BogGator = BogGator EnemyAttrs
  deriving anyclass IsEnemy
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

bogGator :: EnemyCard BogGator
bogGator = enemyWith
  BogGator
  Cards.bogGator
  (2, Static 2, 2)
  (1, 1)
  (preyL .~ LowestSkill SkillAgility)

instance HasSet Trait env LocationId => HasModifiersFor env BogGator where
  getModifiersFor _ (EnemyTarget eid) (BogGator a@EnemyAttrs {..})
    | spawned a && eid == enemyId = do
      bayouLocation <- member Bayou <$> getSet enemyLocation
      pure $ toModifiers a $ if bayouLocation
        then [EnemyFight 2, EnemyEvade 2]
        else []
  getModifiersFor _ _ _ = pure []

instance (EnemyRunner env) => RunMessage env BogGator where
  runMessage msg (BogGator attrs) = BogGator <$> runMessage msg attrs