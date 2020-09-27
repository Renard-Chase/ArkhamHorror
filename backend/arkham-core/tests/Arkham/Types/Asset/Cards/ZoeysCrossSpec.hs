module Arkham.Types.Asset.Cards.ZoeysCrossSpec
  ( spec
  )
where

import TestImport

import qualified Arkham.Types.Enemy.Attrs as Enemy
import qualified Arkham.Types.Investigator.Attrs as Investigator

spec :: Spec
spec = do
  describe "Zoey's Cross" $ do
    context "after engaging an enemy" $ do
      it "spend 1 resource and exhaust to deal one damage to that enemy" $ do
        investigator <- testInvestigator "00000" (Investigator.resources .~ 1)
        enemy <- testEnemy (Enemy.health .~ Static 2)
        location <- testLocation "00000" id
        zoeysCross <- buildAsset "02006"
        game <-
          runGameTest
              investigator
              [ playAsset investigator zoeysCross
              , enemySpawn location enemy
              , moveTo investigator location
              ]
              ((assets %~ insertEntity zoeysCross)
              . (enemies %~ insertEntity enemy)
              . (locations %~ insertEntity location)
              )
            >>= runGameTestOptionMatching
                  "use ability"
                  (\case
                    Run{} -> True
                    _ -> False
                  )
        updated game enemy `shouldSatisfy` hasDamage (1, 0)