module Arkham.Investigator.Cards.RolandBanks
  ( RolandBanks(..)
  , rolandBanks
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Location.Types
import Arkham.Matcher
import Arkham.Message hiding ( EnemyDefeated )
import Arkham.Projection
import Arkham.Timing qualified as Timing

newtype RolandBanks = RolandBanks InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rolandBanks :: InvestigatorCard RolandBanks
rolandBanks = investigator
  RolandBanks
  Cards.rolandBanks
  Stats
    { health = 9
    , sanity = 5
    , willpower = 3
    , intellect = 3
    , combat = 4
    , agility = 2
    }

instance HasAbilities RolandBanks where
  getAbilities (RolandBanks a) =
    [ limitedAbility (PlayerLimit PerRound 1)
        $ reaction
            a
            1
            (OnLocation LocationWithAnyClues <> CanDiscoverCluesAt YourLocation)
            Free
        $ EnemyDefeated Timing.After You AnyEnemy
    ]

instance HasTokenValue RolandBanks where
  getTokenValue iid ElderSign (RolandBanks attrs) | iid == toId attrs = do
    clues <- field LocationClues (investigatorLocation attrs)
    pure $ TokenValue ElderSign (PositiveModifier clues)
  getTokenValue _ token _ = pure $ TokenValue token mempty

instance RunMessage RolandBanks where
  runMessage msg rb@(RolandBanks a) = case msg of
    UseCardAbility _ (isSource a -> True) 1 _ _ -> do
      push $ InvestigatorDiscoverClues (toId a) (investigatorLocation a) 1 Nothing
      pure rb
    _ -> RolandBanks <$> runMessage msg a
