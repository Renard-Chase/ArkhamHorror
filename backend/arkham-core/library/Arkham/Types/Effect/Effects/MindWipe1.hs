module Arkham.Types.Effect.Effects.MindWipe1
  ( mindWipe1
  , MindWipe1(..)
  )
where

import Arkham.Import

import Arkham.Types.Effect.Attrs

newtype MindWipe1 = MindWipe1 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

mindWipe1 :: EffectArgs -> MindWipe1
mindWipe1 = MindWipe1 . uncurry4 (baseAttrs "01068")

instance HasModifiersFor env MindWipe1 where
  getModifiersFor _ target (MindWipe1 Attrs {..}) | target == effectTarget =
    pure [Blank]
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage env MindWipe1 where
  runMessage msg e@(MindWipe1 attrs) = case msg of
    EndPhase -> e <$ unshiftMessage (DisableEffect $ effectId attrs)
    _ -> MindWipe1 <$> runMessage msg attrs