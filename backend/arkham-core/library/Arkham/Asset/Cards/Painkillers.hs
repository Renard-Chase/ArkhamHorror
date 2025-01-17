module Arkham.Asset.Cards.Painkillers
  ( painkillers
  , Painkillers(..)
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher hiding (FastPlayerWindow)
import Arkham.Target

newtype Painkillers = Painkillers AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

painkillers :: AssetCard Painkillers
painkillers = asset Painkillers Cards.painkillers

instance HasAbilities Painkillers where
  getAbilities (Painkillers a) =
    [ restrictedAbility
        a
        1
        (ControlsThis <> InvestigatorExists (You <> InvestigatorWithAnyDamage))
        (FastAbility
          (Costs
            [ UseCost (AssetWithId $ toId a) Supply 1
            , ExhaustCost (toTarget a)
            , HorrorCost (toSource a) YouTarget 1
            ]
          )
        )
    ]

instance RunMessage Painkillers where
  runMessage msg a@(Painkillers attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source ->
      a <$ push (HealDamage (InvestigatorTarget iid) 1)
    _ -> Painkillers <$> runMessage msg attrs
