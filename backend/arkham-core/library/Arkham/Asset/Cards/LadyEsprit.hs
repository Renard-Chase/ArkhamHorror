module Arkham.Asset.Cards.LadyEsprit
  ( LadyEsprit(..)
  , ladyEsprit
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Target

newtype LadyEsprit = LadyEsprit AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

ladyEsprit :: AssetCard LadyEsprit
ladyEsprit = allyWith LadyEsprit Cards.ladyEsprit (2, 4) (isStoryL .~ True)

instance HasAbilities LadyEsprit where
  getAbilities (LadyEsprit x) =
    [ restrictedAbility
        x
        1
        OnSameLocation
        (ActionAbility Nothing $ Costs
          [ ActionCost 1
          , ExhaustCost (toTarget x)
          , HorrorCost (toSource x) (toTarget x) 1
          ]
        )
    ]

instance RunMessage LadyEsprit where
  runMessage msg a@(LadyEsprit attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      push $ chooseOne
        iid
        [ ComponentLabel
          (InvestigatorComponent iid DamageToken)
          [HealDamage (InvestigatorTarget iid) 2]
        , ComponentLabel
          (InvestigatorComponent iid ResourceToken)
          [TakeResources iid 2 False]
        ]
      pure a
    _ -> LadyEsprit <$> runMessage msg attrs
