module Arkham.Types.Asset.Cards.PhysicalTrainingSpec
  ( spec
  )
where

import TestImport

import Arkham.Types.Investigator.Attrs (Attrs(..))
import Arkham.Types.Token

spec :: Spec
spec = describe "Physical Training" $ do
  it "Adds 1 to willpower check for each resource spent" $ do
    physicalTraining <- buildAsset "01017"
    investigator <- testInvestigator "00000"
      $ \attrs -> attrs { investigatorWillpower = 1, investigatorResources = 2 }
    scenario' <- testScenario "00000" id
    game <-
      runGameTest
        investigator
        [ SetTokens [Zero]
        , playAsset investigator physicalTraining
        , beginSkillTest investigator SkillWillpower 3
        ]
        ((assets %~ insertEntity physicalTraining) . (scenario ?~ scenario'))
      >>= runGameTestOptionMatching
            "use ability"
            (\case
              Run{} -> True
              _ -> False
            )
      >>= runGameTestOptionMatching
            "use ability"
            (\case
              Run{} -> True
              _ -> False
            )
      >>= runGameTestOptionMatching
            "start skill test"
            (\case
              StartSkillTest{} -> True
              _ -> False
            )
      >>= runGameTestOnlyOption "apply results"
    game `shouldSatisfy` hasProcessedMessage
      (PassedSkillTest "00000" Nothing TestSource (TokenTarget Zero) 0)

  it "Adds 1 to combat check for each resource spent" $ do
    physicalTraining <- buildAsset "01017"
    investigator <- testInvestigator "00000"
      $ \attrs -> attrs { investigatorCombat = 1, investigatorResources = 2 }
    scenario' <- testScenario "00000" id
    game <-
      runGameTest
        investigator
        [ SetTokens [Zero]
        , playAsset investigator physicalTraining
        , beginSkillTest investigator SkillCombat 3
        ]
        ((assets %~ insertEntity physicalTraining) . (scenario ?~ scenario'))
      >>= runGameTestOptionMatching
            "use ability"
            (\case
              Run{} -> True
              _ -> False
            )
      >>= runGameTestOptionMatching
            "use ability"
            (\case
              Run{} -> True
              _ -> False
            )
      >>= runGameTestOptionMatching
            "start skill test"
            (\case
              StartSkillTest{} -> True
              _ -> False
            )
      >>= runGameTestOnlyOption "apply results"
    game `shouldSatisfy` hasProcessedMessage
      (PassedSkillTest "00000" Nothing TestSource (TokenTarget Zero) 0)