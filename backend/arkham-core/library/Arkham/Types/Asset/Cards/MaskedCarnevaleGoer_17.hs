module Arkham.Types.Asset.Cards.MaskedCarnevaleGoer_17
  ( maskedCarnevaleGoer_17
  , MaskedCarnevaleGoer_17(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.EncounterCard
import qualified Arkham.Enemy.Cards as Enemies
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.Window

newtype MaskedCarnevaleGoer_17 = MaskedCarnevaleGoer_17 AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

maskedCarnevaleGoer_17 :: AssetCard MaskedCarnevaleGoer_17
maskedCarnevaleGoer_17 =
  asset MaskedCarnevaleGoer_17 Cards.maskedCarnevaleGoer_17

ability :: AssetAttrs -> Ability
ability attrs =
  (mkAbility attrs 1 (ActionAbility Nothing $ Costs [ActionCost 1, ClueCost 1]))
    { abilityRestrictions = OnLocation <$> assetLocation attrs
    }

instance HasActions env MaskedCarnevaleGoer_17 where
  getActions iid NonFast (MaskedCarnevaleGoer_17 attrs) =
    pure [UseAbility iid (ability attrs)]
  getActions iid window (MaskedCarnevaleGoer_17 attrs) =
    getActions iid window attrs

instance HasModifiersFor env MaskedCarnevaleGoer_17

instance
  ( HasSet InvestigatorId env LocationId
  , HasQueue env
  , HasModifiersFor env ()
  )
  => RunMessage env MaskedCarnevaleGoer_17 where
  runMessage msg a@(MaskedCarnevaleGoer_17 attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      case assetLocation attrs of
        Just lid -> do
          investigatorIds <- getSetList lid
          let
            donLagorioId = EnemyId $ toCardId attrs
            donLagorio = EncounterCard
              $ lookupEncounterCard Enemies.donLagorio (toCardId attrs)
          a <$ pushAll
            ([ RemoveFromGame (toTarget attrs)
             , CreateEnemyAt donLagorio lid Nothing
             ]
            <> [ EnemyAttack iid donLagorioId | iid <- investigatorIds ]
            )
        Nothing -> error "not possible"
    _ -> MaskedCarnevaleGoer_17 <$> runMessage msg attrs