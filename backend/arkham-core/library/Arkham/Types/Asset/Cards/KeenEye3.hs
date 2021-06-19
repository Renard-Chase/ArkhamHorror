module Arkham.Types.Asset.Cards.KeenEye3
  ( keenEye3
  , KeenEye3(..)
  ) where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.AssetId
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Effect.Window
import Arkham.Types.EffectMetadata
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Window

newtype KeenEye3 = KeenEye3 AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

keenEye3 :: AssetId -> KeenEye3
keenEye3 uuid = KeenEye3 $ baseAttrs uuid "02185"

instance HasActions env KeenEye3 where
  getActions iid FastPlayerWindow (KeenEye3 a) | ownedBy a iid = do
    pure
      [ ActivateCardAbilityAction
          iid
          (mkAbility (toSource a) idx (FastAbility $ ResourceCost 2))
      | idx <- [1 .. 2]
      ]
  getActions _ _ _ = pure []

instance HasModifiersFor env KeenEye3 where
  getModifiersFor = noModifiersFor

instance AssetRunner env => RunMessage env KeenEye3 where
  runMessage msg a@(KeenEye3 attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source ->
      a <$ unshiftMessage
        (CreateWindowModifierEffect
          EffectPhaseWindow
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillIntellect 1])
          source
          (InvestigatorTarget iid)
        )
    UseCardAbility iid source _ 2 _ | isSource attrs source ->
      a <$ unshiftMessage
        (CreateWindowModifierEffect
          EffectPhaseWindow
          (EffectModifiers $ toModifiers attrs [SkillModifier SkillCombat 1])
          source
          (InvestigatorTarget iid)
        )
    _ -> KeenEye3 <$> runMessage msg attrs
