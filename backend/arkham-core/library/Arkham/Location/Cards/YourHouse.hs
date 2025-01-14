module Arkham.Location.Cards.YourHouse
  ( YourHouse(..)
  , yourHouse
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Cost
import Arkham.Criteria
import Arkham.Enemy.Cards qualified as Cards
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window

newtype YourHouse = YourHouse LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

yourHouse :: LocationCard YourHouse
yourHouse = location YourHouse Cards.yourHouse 2 (PerPlayer 1)

instance HasModifiersFor YourHouse where
  getModifiersFor (EnemyTarget eid) (YourHouse attrs) = do
    isGhoulPriest <- member eid <$> select (enemyIs $ Cards.ghoulPriest)
    pure $ toModifiers
      attrs
      [ ForceSpawnLocation (LocationWithId $ toId attrs) | isGhoulPriest ]
  getModifiersFor _ _ = pure []

instance HasAbilities YourHouse where
  getAbilities (YourHouse x) | locationRevealed x =
    withBaseAbilities x
      $ [ mkAbility x 1
          $ ForcedAbility
              (EnemySpawns Timing.When Anywhere $ enemyIs Cards.ghoulPriest)
        , limitedAbility (PlayerLimit PerTurn 1)
          $ restrictedAbility x 2 Here (ActionAbility Nothing $ ActionCost 1)
        ]
  getAbilities (YourHouse x) = getAbilities x

instance RunMessage YourHouse where
  runMessage msg l@(YourHouse attrs) = case msg of
    UseCardAbility _ source 1 [Window _ (Window.EnemySpawns _ _)] _
      | isSource attrs source -> pure l
    UseCardAbility iid source 2 _ _ | isSource attrs source ->
      l <$ pushAll [DrawCards iid 1 False, TakeResources iid 1 False]
    _ -> YourHouse <$> runMessage msg attrs
