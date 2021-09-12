module Arkham.Types.Skill.Cards.SayYourPrayers
  ( sayYourPrayers
  , SayYourPrayers(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Skill.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Skill.Attrs
import Arkham.Types.Skill.Runner

newtype SayYourPrayers = SayYourPrayers SkillAttrs
  deriving anyclass (IsSkill, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sayYourPrayers :: SkillCard SayYourPrayers
sayYourPrayers = skill SayYourPrayers Cards.sayYourPrayers

instance SkillRunner env => RunMessage env SayYourPrayers where
  runMessage msg (SayYourPrayers attrs) =
    SayYourPrayers <$> runMessage msg attrs
