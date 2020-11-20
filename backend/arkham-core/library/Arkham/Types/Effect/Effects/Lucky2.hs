module Arkham.Types.Effect.Effects.Lucky2
  ( lucky2
  , Lucky2(..)
  )
where

import Arkham.Import

import Arkham.Types.Effect.Attrs

newtype Lucky2 = Lucky2 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

lucky2 :: EffectArgs -> Lucky2
lucky2 = Lucky2 . uncurry4 (baseAttrs "01084")

instance HasModifiersFor env Lucky2 where
  getModifiersFor _ target (Lucky2 Attrs {..}) | target == effectTarget =
    pure [AnySkillValue 2]
  getModifiersFor _ _ _ = pure []

instance HasQueue env => RunMessage env Lucky2 where
  runMessage msg e@(Lucky2 attrs) = case msg of
    CreatedEffect eid _ _ (InvestigatorTarget _) | eid == effectId attrs ->
      e <$ unshiftMessage RerunSkillTest
    SkillTestEnds -> e <$ unshiftMessage (DisableEffect $ effectId attrs)
    _ -> Lucky2 <$> runMessage msg attrs