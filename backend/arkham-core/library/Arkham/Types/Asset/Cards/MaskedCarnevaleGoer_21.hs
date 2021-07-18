module Arkham.Types.Asset.Cards.MaskedCarnevaleGoer_21
  ( maskedCarnevaleGoer_21
  , MaskedCarnevaleGoer_21(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.PlayerCard
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Message
import Arkham.Types.Window

newtype MaskedCarnevaleGoer_21 = MaskedCarnevaleGoer_21 AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

maskedCarnevaleGoer_21 :: AssetCard MaskedCarnevaleGoer_21
maskedCarnevaleGoer_21 =
  asset MaskedCarnevaleGoer_21 Cards.maskedCarnevaleGoer_21

ability :: AssetAttrs -> Ability
ability attrs =
  (mkAbility attrs 1 (ActionAbility Nothing $ Costs [ActionCost 1, ClueCost 1]))
    { abilityRestrictions = OnLocation <$> assetLocation attrs
    }

instance HasActions env MaskedCarnevaleGoer_21 where
  getActions iid NonFast (MaskedCarnevaleGoer_21 attrs) =
    pure [UseAbility iid (ability attrs)]
  getActions iid window (MaskedCarnevaleGoer_21 attrs) =
    getActions iid window attrs

instance HasModifiersFor env MaskedCarnevaleGoer_21

instance
  ( HasQueue env
  , HasModifiersFor env ()
  )
  => RunMessage env MaskedCarnevaleGoer_21 where
  runMessage msg a@(MaskedCarnevaleGoer_21 attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      case assetLocation attrs of
        Just lid -> do
          let
            innocentReveler = PlayerCard
              $ lookupPlayerCard Cards.innocentReveler (toCardId attrs)
          a <$ pushAll
            [ RemoveFromGame (toTarget attrs)
            , CreateStoryAssetAt innocentReveler lid
            ]
        Nothing -> error "not possible"
    _ -> MaskedCarnevaleGoer_21 <$> runMessage msg attrs
