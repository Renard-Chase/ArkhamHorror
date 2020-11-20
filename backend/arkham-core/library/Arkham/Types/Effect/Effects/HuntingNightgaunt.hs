module Arkham.Types.Effect.Effects.HuntingNightgaunt
  ( huntingNightgaunt
  , HuntingNightgaunt(..)
  )
where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Effect.Attrs

newtype HuntingNightgaunt = HuntingNightgaunt Attrs
  deriving newtype (Show, ToJSON, FromJSON)

huntingNightgaunt :: EffectArgs -> HuntingNightgaunt
huntingNightgaunt = HuntingNightgaunt . uncurry4 (baseAttrs "01172")

instance HasModifiersFor env HuntingNightgaunt where
  getModifiersFor (SkillTestSource _ _ (Just Evade)) (DrawnTokenTarget _) (HuntingNightgaunt Attrs {..})
    = pure [DoubleNegativeModifiersOnTokens]
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage env HuntingNightgaunt where
  runMessage msg e@(HuntingNightgaunt attrs) = case msg of
    SkillTestEnds -> e <$ unshiftMessage (DisableEffect $ effectId attrs)
    _ -> HuntingNightgaunt <$> runMessage msg attrs