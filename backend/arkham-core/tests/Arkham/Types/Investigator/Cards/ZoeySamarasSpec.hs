module Arkham.Types.Investigator.Cards.ZoeySamarasSpec
  ( spec
  )
where

import TestImport.Lifted

import qualified Arkham.Types.Enemy.Attrs as Enemy

spec :: Spec
spec = do
  describe "Zoey Samaras" $ do
    it "elder sign token gives +1" $ do
      let zoeySamaras = lookupInvestigator "02001"
      runGameTest zoeySamaras [] id $ do
        runMessagesNoLogging
        token <- getTokenValue zoeySamaras (toId zoeySamaras) ElderSign
        tokenValue token `shouldBe` Just 1

    it "elder sign token gives +1 and does +1 damage for attacks" $ do
      let zoeySamaras = lookupInvestigator "02001" -- combat is 4
      enemy <- testEnemy ((Enemy.healthL .~ Static 3) . (Enemy.fightL .~ 5))
      location <- testLocation "00000" id
      runGameTest
          zoeySamaras
          [ SetTokens [ElderSign]
          , enemySpawn location enemy
          , moveTo zoeySamaras location
          , fightEnemy zoeySamaras enemy
          ]
          ((enemiesL %~ insertEntity enemy)
          . (locationsL %~ insertEntity location)
          )
        $ do
            runMessagesNoLogging
            runGameTestOptionMatching
              "skip ability"
              (\case
                Continue{} -> True
                _ -> False
              )
            runGameTestOnlyOption "start skill test"
            runGameTestOnlyOption "apply results"
            updated enemy `shouldSatisfyM` hasDamage (2, 0)

    it "allows you to gain a resource each time you are engaged by an enemy"
      $ do
          let zoeySamaras = lookupInvestigator "02001"
          location <- testLocation "00000" id
          enemy1 <- testEnemy id
          enemy2 <- testEnemy id
          runGameTest
              zoeySamaras
              [ enemySpawn location enemy1
              , moveTo zoeySamaras location
              , enemySpawn location enemy2
              ]
              ((locationsL %~ insertEntity location)
              . (enemiesL %~ insertEntity enemy1)
              . (enemiesL %~ insertEntity enemy2)
              )
            $ do
                runMessagesNoLogging
                runGameTestOptionMatching
                  "use ability"
                  (\case
                    Run{} -> True
                    _ -> False
                  )
                runGameTestOptionMatching
                  "use ability again"
                  (\case
                    Run{} -> True
                    _ -> False
                  )
                updatedResourceCount zoeySamaras `shouldReturn` 2
