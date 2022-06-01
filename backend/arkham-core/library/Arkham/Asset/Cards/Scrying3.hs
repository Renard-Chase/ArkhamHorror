module Arkham.Asset.Cards.Scrying3
  ( Scrying3(..)
  , scrying3
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Cost
import Arkham.Criteria
import Arkham.Matcher
import Arkham.Target
import Arkham.Trait
import Arkham.Zone

newtype Scrying3 = Scrying3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

scrying3 :: AssetCard Scrying3
scrying3 = asset Scrying3 Cards.scrying3

instance HasAbilities Scrying3 where
  getAbilities (Scrying3 a) =
    [ restrictedAbility a 1 OwnsThis $ FastAbility $ Costs
        [UseCost (AssetWithId $ toId a) Charge 1, ExhaustCost $ toTarget a]
    ]

instance AssetRunner env => RunMessage env Scrying3 where
  runMessage msg a@(Scrying3 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> do
      targets <- map InvestigatorTarget <$> getInvestigatorIds
      a <$ push
        (chooseOne iid
        $ Search
            iid
            source
            EncounterDeckTarget
            [(FromTopOfDeck 3, PutBackInAnyOrder)]
            AnyCard
            (DeferSearchedToTarget $ toTarget attrs)
        : [ Search
              iid
              source
              target
              [(FromTopOfDeck 3, PutBackInAnyOrder)]
              AnyCard
            (DeferSearchedToTarget $ toTarget attrs)
          | target <- targets
          ]
        )
    SearchFound iid (isTarget attrs -> True)  _ cards -> do
      when (any (\c -> any (`elem` toTraits c) [Omen, Terror]) cards) $
        push $ InvestigatorAssignDamage iid (toSource attrs) DamageAny 0 1
      pure a
    _ -> Scrying3 <$> runMessage msg attrs