module Arkham.Event.Cards.Persuasion
  ( persuasion
  , Persuasion(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Enemy.Types
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Game.Helpers
import Arkham.Helpers.SkillTest
import Arkham.Investigator.Types
import Arkham.Matcher hiding ( EnemyEvaded )
import Arkham.Message
import Arkham.Projection
import Arkham.SkillType
import Arkham.Target
import Arkham.Trait

newtype Persuasion = Persuasion EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

persuasion :: EventCard Persuasion
persuasion = event Persuasion Cards.persuasion

instance RunMessage Persuasion where
  runMessage msg e@(Persuasion attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ _ | eid == toId attrs -> do
      mlocation <- field InvestigatorLocation iid
      case mlocation of
        Just location -> do
          enemies <-
            selectList
            $ enemyAt location
            <> EnemyWithTrait Humanoid
            <> NonWeaknessEnemy
          enemiesWithHorror <- traverse
            (traverseToSnd (field EnemySanityDamage))
            enemies
          pushAll
            [ chooseOne
              iid
              [ targetLabel
                  eid
                  [ BeginSkillTest
                      iid
                      (toSource attrs)
                      (EnemyTarget enemyId)
                      Nothing
                      SkillIntellect
                      (3 + horror)
                  ]
              | (enemyId, horror) <- enemiesWithHorror
              ]
            , Discard (toTarget attrs)
            ]
        _ -> error "investigator not at location"
      pure e
    PassedSkillTest iid _ _ SkillTestInitiatorTarget{} _ _ -> do
      mSkillTestTarget <- getSkillTestTarget
      case mSkillTestTarget of
        Just (EnemyTarget eid) -> do
          isElite <- eid <=~> EliteEnemy
          if isElite
            then push $ EnemyEvaded iid eid
            else push $ ShuffleBackIntoEncounterDeck (EnemyTarget eid)
        _ -> error "Invalid target"
      pure e
    _ -> Persuasion <$> runMessage msg attrs
