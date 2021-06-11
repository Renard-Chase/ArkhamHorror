module Arkham.Types.Asset.Cards.BandolierSpec
  ( spec
  )
where

import TestImport.Lifted

import qualified Arkham.Types.Investigator.Attrs as Investigator
import Arkham.Types.Slot
import Arkham.Types.Trait

spec :: Spec
spec = describe "Bandolier" $ do
  it "adds a weapon hand slot" $ do
    investigator <- testInvestigator "00000" id
    bandolier <- buildAsset "02147"
    runGameTest
        investigator
        [playAsset investigator bandolier]
        (assetsL %~ insertEntity bandolier)
      $ do
          runMessagesNoLogging
          investigator' <- updated investigator
          let
            slots =
              fromMaybe []
                $ toAttrs investigator'
                ^? Investigator.slotsL
                . ix HandSlot
          slots `shouldSatisfy` elem
            (TraitRestrictedSlot (toSource bandolier) Weapon Nothing)
