module Arkham.Types.SkillTest where

import Arkham.Prelude

import Arkham.Types.Action
import Arkham.Types.Id
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target

class HasSkillTest env where
  getSkillTest :: MonadReader env m => m (Maybe SkillTest)

data SkillTest

skillTestInvestigator :: SkillTest -> InvestigatorId
skillTestSkillType :: SkillTest -> SkillType
skillTestAction :: SkillTest -> Maybe Action
skillTestSource :: SkillTest -> Source
skillTestTarget :: SkillTest -> Target