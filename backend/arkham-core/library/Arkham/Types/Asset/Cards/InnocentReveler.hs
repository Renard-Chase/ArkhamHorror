module Arkham.Types.Asset.Cards.InnocentReveler
  ( innocentReveler
  , InnocentReveler(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Card
import Arkham.Types.Card.PlayerCard
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Window

newtype InnocentReveler = InnocentReveler AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

innocentReveler :: AssetCard InnocentReveler
innocentReveler = ally InnocentReveler Cards.innocentReveler (2, 2)

ability :: AssetAttrs -> Ability
ability a = mkAbility a 1 (ActionAbility (Just Parley) (ActionCost 1))

instance HasActions env InnocentReveler where
  getActions iid NonFast (InnocentReveler attrs) = pure
    [ UseAbility iid (ability attrs) | isNothing (assetInvestigator attrs) ]
  getActions iid window (InnocentReveler attrs) = getActions iid window attrs

instance HasModifiersFor env InnocentReveler

instance
  ( HasSet InvestigatorId env ()
  , HasQueue env
  , HasModifiersFor env ()
  )
  => RunMessage env InnocentReveler where
  runMessage msg a@(InnocentReveler attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a
        <$ push
             (BeginSkillTest
               iid
               source
               (toTarget attrs)
               (Just Parley)
               SkillIntellect
               2
             )
    PassedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> a <$ push (TakeControlOfAsset iid $ toId attrs)
    When (Discard target) | isTarget attrs target -> do
      investigatorIds <- getInvestigatorIds
      let
        card = PlayerCard $ lookupPlayerCard (toCardDef attrs) (toCardId attrs)
      a <$ pushAll
        (PlaceUnderneath AgendaDeckTarget [card]
        : [ InvestigatorAssignDamage iid' (toSource attrs) DamageAny 0 1
          | iid' <- investigatorIds
          ]
        )
    _ -> InnocentReveler <$> runMessage msg attrs
