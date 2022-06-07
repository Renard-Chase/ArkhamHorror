module Arkham.Scenarios.CurseOfTheRougarou.Helpers where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Enemy.Cards qualified as Cards
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Id
import Arkham.Json
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Trait

bayouLocations :: GameT (HashSet LocationId)
bayouLocations = select $ LocationWithTrait Bayou

nonBayouLocations :: GameT (HashSet LocationId)
nonBayouLocations = select $ LocationWithoutTrait Bayou

getTheRougarou :: GameT (Maybe EnemyId)
getTheRougarou = selectOne $ enemyIs Cards.theRougarou

locationsWithLabels :: Trait -> [Card] -> GameT [(Text, Card)]
locationsWithLabels trait locationSet = do
  shuffled <- shuffleM (before <> after)
  pure $ zip labels (bayou : shuffled)
 where
  labels =
    [ pack (camelCase $ show trait) <> "Bayou"
    , pack (camelCase $ show trait) <> "1"
    , pack (camelCase $ show trait) <> "2"
    ]
  (before, bayou : after) = break (elem Bayou . toTraits) locationSet

locationsByTrait :: HashMap Trait [CardDef]
locationsByTrait = mapFromList
  [ ( NewOrleans
    , [Locations.cursedShores, Locations.gardenDistrict, Locations.broadmoor]
    )
  , ( Riverside
    , [ Locations.brackishWaters
      , Locations.audubonPark
      , Locations.fauborgMarigny
      ]
    )
  , ( Wilderness
    , [ Locations.forgottenMarsh
      , Locations.trappersCabin
      , Locations.twistedUnderbrush
      ]
    )
  , ( Unhallowed
    , [Locations.foulSwamp, Locations.ritualGrounds, Locations.overgrownCairns]
    )
  ]

