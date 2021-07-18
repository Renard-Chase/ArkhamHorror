module Arkham.Types.Asset.Cards.MaskedCarnevaleGoer_19
  ( maskedCarnevaleGoer_19
  , MaskedCarnevaleGoer_19(..)
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

newtype MaskedCarnevaleGoer_19 = MaskedCarnevaleGoer_19 AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

maskedCarnevaleGoer_19 :: AssetCard MaskedCarnevaleGoer_19
maskedCarnevaleGoer_19 =
  asset MaskedCarnevaleGoer_19 Cards.maskedCarnevaleGoer_19

ability :: AssetAttrs -> Ability
ability attrs =
  (mkAbility attrs 1 (ActionAbility Nothing $ Costs [ActionCost 1, ClueCost 1]))
    { abilityRestrictions = OnLocation <$> assetLocation attrs
    }

instance HasActions env MaskedCarnevaleGoer_19 where
  getActions iid NonFast (MaskedCarnevaleGoer_19 attrs) =
    pure [UseAbility iid (ability attrs)]
  getActions iid window (MaskedCarnevaleGoer_19 attrs) =
    getActions iid window attrs

instance HasModifiersFor env MaskedCarnevaleGoer_19

instance
  ( HasSet InvestigatorId env LocationId
  , HasQueue env
  , HasModifiersFor env ()
  )
  => RunMessage env MaskedCarnevaleGoer_19 where
  runMessage msg a@(MaskedCarnevaleGoer_19 attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      case assetLocation attrs of
        Just lid -> do
          investigatorIds <- getSetList lid
          let
            salvatoreNeriId = EnemyId $ toCardId attrs
            salvatoreNeri = EncounterCard
              $ lookupEncounterCard Enemies.salvatoreNeri (toCardId attrs)
          a <$ pushAll
            ([ RemoveFromGame (toTarget attrs)
             , CreateEnemyAt salvatoreNeri lid Nothing
             ]
            <> [ EnemyAttack iid salvatoreNeriId | iid <- investigatorIds ]
            )
        Nothing -> error "not possible"
    _ -> MaskedCarnevaleGoer_19 <$> runMessage msg attrs