module Arkham.Asset.Cards.OliveMcBride
  ( oliveMcBride
  , OliveMcBride(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.ChaosBagStepState
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Timing qualified as Timing
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window

newtype OliveMcBride = OliveMcBride AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

oliveMcBride :: AssetCard OliveMcBride
oliveMcBride = ally OliveMcBride Cards.oliveMcBride (1, 3)

instance HasAbilities OliveMcBride where
  getAbilities (OliveMcBride a) =
    [ restrictedAbility a 1 ControlsThis
        $ ReactionAbility (WouldRevealChaosToken Timing.When You)
        $ ExhaustCost (toTarget a)
    ]

instance RunMessage OliveMcBride where
  runMessage msg a@(OliveMcBride attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 [Window Timing.When (Window.WouldRevealChaosToken drawSource _)] _
      -> do
        push $ ReplaceCurrentDraw drawSource iid $ Choose
          2
          [Undecided Draw, Undecided Draw, Undecided Draw]
          []
        pure a
    _ -> OliveMcBride <$> runMessage msg attrs