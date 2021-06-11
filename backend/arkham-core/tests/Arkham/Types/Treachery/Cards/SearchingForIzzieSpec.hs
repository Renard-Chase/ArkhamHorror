module Arkham.Types.Treachery.Cards.SearchingForIzzieSpec
  ( spec
  )
where

import TestImport.Lifted

spec :: Spec
spec = describe "Searching for Izzie" $ do
  it "attaches to the location farthest away from you" $ do
    investigator <- testInvestigator "00000" id
    searchingForIzzie <- buildPlayerCard "02011"
    (location1, location2) <- testConnectedLocations id id
    runGameTest
        investigator
        [ placedLocation location1
        , placedLocation location2
        , loadDeck investigator [searchingForIzzie]
        , moveTo investigator location1
        , drawCards investigator 1
        ]
        ((locationsL %~ insertEntity location1)
        . (locationsL %~ insertEntity location2)
        )
      $ do
          runMessagesNoLogging
          location2' <- updated location2
          hasTreacheryWithMatchingCardCode
              (PlayerCard searchingForIzzie)
              location2'
            `shouldReturn` True

  it "takes 2 actions and is discarded on a successful investigation" $ do
    investigator <- testInvestigator "00000" id
    searchingForIzzie <- buildPlayerCard "02011"
    location <- testLocation "00000" id
    runGameTest
        investigator
        [ SetTokens [Zero]
        , loadDeck investigator [searchingForIzzie]
        , moveTo investigator location
        , drawCards investigator 1
        , moveTo investigator location
        ]
        (locationsL %~ insertEntity location)
      $ do
          runMessagesNoLogging
          game <- getTestGame
          let
            updatedSearchingForIzzie = game ^?! treacheriesL . to toList . ix 0

          [searchingForIzzieAction] <- getActionsOf
            investigator
            NonFast
            updatedSearchingForIzzie

          runGameTestMessages [searchingForIzzieAction]
          runGameTestOnlyOption "start skill test"
          runGameTestOnlyOption "apply results"
          location' <- updated location
          hasTreacheryWithMatchingCardCode
              (PlayerCard searchingForIzzie)
              location'
            `shouldReturn` False
          investigator' <- updated investigator
          isInDiscardOf investigator' updatedSearchingForIzzie
            `shouldReturn` True
          actionsRemaining investigator' `shouldBe` 1
          investigator' `shouldSatisfy` hasTrauma (0, 0)

  it "causes 1 mental trauma if not discarded" $ do
    investigator <- testInvestigator "00000" id
    searchingForIzzie <- buildPlayerCard "02011"
    location <- testLocation "00000" id
    runGameTest
        investigator
        [ loadDeck investigator [searchingForIzzie]
        , moveTo investigator location
        , drawCards investigator 1
        , EndOfGame
        ]
        (locationsL %~ insertEntity location)
      $ do
          runMessagesNoLogging
          updated investigator `shouldSatisfyM` hasTrauma (0, 1)
