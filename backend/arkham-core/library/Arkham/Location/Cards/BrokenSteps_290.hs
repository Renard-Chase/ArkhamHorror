module Arkham.Location.Cards.BrokenSteps_290
  ( brokenSteps_290
  , BrokenSteps_290(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Card
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Scenario.Attrs (Field(..))
import Arkham.Timing qualified as Timing
import Arkham.Trait

newtype BrokenSteps_290 = BrokenSteps_290 LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

brokenSteps_290 :: LocationCard BrokenSteps_290
brokenSteps_290 = location
  BrokenSteps_290
  Cards.brokenSteps_290
  3
  (Static 0)
  Equals
  [Squiggle, Triangle, Diamond, Square]

instance HasAbilities BrokenSteps_290 where
  getAbilities (BrokenSteps_290 a) =
    withBaseAbilities a
      $ [ mkAbility a 1
          $ ForcedAbility
          $ Enters Timing.After You
          $ LocationWithId
          $ toId a
        ]

instance RunMessage BrokenSteps_290 where
  runMessage msg l@(BrokenSteps_290 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      hasAssets <- selectAny $ assetControlledBy iid <> DiscardableAsset
      mCultistCard <- find (`cardMatch` (CardWithTrait Cultist <> CardWithType EnemyType))
        <$> scenarioField ScenarioDiscard
      let
        choices =
          [ Label "Discard an asset" [ChooseAndDiscardAsset iid AnyAsset]
          | hasAssets
          ]
          <> [ Label
                 "Draw the topmost cultist enemy in the encounter discard pile"
                 [FindAndDrawEncounterCard iid $ CardWithId $ toCardId c]
             | c <- maybeToList mCultistCard
             ]
      unless (null choices) $ push $ chooseOne iid choices
      pure l
    _ -> BrokenSteps_290 <$> runMessage msg attrs