module Arkham.Types.Effect
  ( lookupEffect
  , buildSkillTestEffect
  , buildTokenValueEffect
  , buildPhaseEffect
  , Effect(..)
  )
where

import Arkham.Import

import Arkham.Types.Effect.Attrs
import Arkham.Types.Effect.Effects

data Effect
  = OnTheLam' OnTheLam
  | MindOverMatter' MindOverMatter
  | Deduction' Deduction
  | Burglary' Burglary
  | Shrivelling' Shrivelling
  | BlindingLight' BlindingLight
  | MindWipe1' MindWipe1
  | BlindingLight2' BlindingLight2
  | BaseballBat' BaseballBat
  | Lucky' Lucky
  | Lucky2' Lucky2
  | WillToSurvive4' WillToSurvive4
  | SureGamble3' SureGamble3
  | ArkhamWoodsTwistingPaths' ArkhamWoodsTwistingPaths
  | HuntingNightgaunt' HuntingNightgaunt
  | LetMeHandleThis' LetMeHandleThis
  | MindWipe3' MindWipe3
  | JeremiahPierce' JeremiahPierce
  | CurseOfTheRougarouTabletToken' CurseOfTheRougarouTabletToken
  | CursedShores' CursedShores
  | SkillTestEffect' SkillTestEffect
  | PhaseEffect' PhaseEffect
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

deriving anyclass instance HasModifiersFor env Effect
deriving anyclass instance HasQueue env => RunMessage env Effect

lookupEffect
  :: CardCode
  -> EffectId
  -> Maybe (EffectMetadata Message)
  -> Source
  -> Target
  -> Effect
lookupEffect cardCode eid mmetadata source target = effect
  (eid, mmetadata, source, target)
 where
  effect = findWithDefault
    (error $ "Unknown effect: " <> show cardCode)
    cardCode
    allEffects

allEffects :: HashMap CardCode (EffectArgs -> Effect)
allEffects = mapFromList
  [ ("01010", OnTheLam' . onTheLam)
  , ("01036", MindOverMatter' . mindOverMatter)
  , ("01039", Deduction' . deduction)
  , ("01045", Burglary' . burglary)
  , ("01060", Shrivelling' . shrivelling)
  , ("01066", BlindingLight' . blindingLight)
  , ("01068", MindWipe1' . mindWipe1)
  , ("01069", BlindingLight2' . blindingLight2)
  , ("01074", BaseballBat' . baseballBat)
  , ("01080", Lucky' . lucky)
  , ("01084", Lucky2' . lucky2)
  , ("01085", WillToSurvive4' . willToSurvive4)
  , ("01088", SureGamble3' . sureGamble3)
  , ("01151", ArkhamWoodsTwistingPaths' . arkhamWoodsTwistingPaths)
  , ("01172", HuntingNightgaunt' . huntingNightgaunt)
  , ("03022", LetMeHandleThis' . letMeHandleThis)
  , ("50008", MindWipe3' . mindWipe3)
  , ("50044", JeremiahPierce' . jeremiahPierce)
  , ("81001", CurseOfTheRougarouTabletToken' . curseOfTheRougarouTabletToken)
  , ("81007", CursedShores' . cursedShores)
  ]

buildSkillTestEffect
  :: EffectId -> EffectMetadata Message -> Source -> Target -> Effect
buildSkillTestEffect eid metadata source target =
  SkillTestEffect' $ skillTestEffect eid metadata source target

buildTokenValueEffect :: EffectId -> Int -> Source -> Target -> Effect
buildTokenValueEffect eid n source target = SkillTestEffect'
  $ skillTestEffect eid (EffectModifiers [TokenValueModifier n]) source target

buildPhaseEffect
  :: EffectId -> EffectMetadata Message -> Source -> Target -> Effect
buildPhaseEffect eid metadata source target =
  PhaseEffect' $ phaseEffect eid metadata source target
