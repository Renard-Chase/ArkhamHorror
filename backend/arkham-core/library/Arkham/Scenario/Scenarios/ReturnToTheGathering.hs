module Arkham.Scenario.Scenarios.ReturnToTheGathering where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Asset.Cards qualified as Assets
import Arkham.Card
import Arkham.Classes
import Arkham.Difficulty
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Location.Cards qualified as Locations
import Arkham.Message
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.Scenario.Scenarios.TheGathering
import Arkham.Scenarios.TheGathering.Story

newtype ReturnToTheGathering = ReturnToTheGathering TheGathering
  deriving stock Generic
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

returnToTheGathering :: Difficulty -> ReturnToTheGathering
returnToTheGathering difficulty = scenario
  (ReturnToTheGathering . TheGathering)
  "50011"
  "Return To The Gathering"
  difficulty
  [ ".     .         farAboveYourHouse  ."
  , ".     bedroom   attic              ."
  , "study guestHall holeInTheWall      parlor"
  , ".     bathroom  cellar             ."
  , ".     .         deepBelowYourHouse ."
  ]

instance HasTokenValue ReturnToTheGathering where
  getTokenValue iid tokenFace (ReturnToTheGathering theGathering') =
    getTokenValue iid tokenFace theGathering'

instance RunMessage ReturnToTheGathering where
  runMessage msg (ReturnToTheGathering theGathering'@(TheGathering attrs)) =
    case msg of
      Setup -> do
        investigatorIds <- allInvestigatorIds

        encounterDeck <- buildEncounterDeckExcluding
          [Enemies.ghoulPriest]
          [ EncounterSet.ReturnToTheGathering
          , EncounterSet.TheGathering
          , EncounterSet.Rats
          , EncounterSet.GhoulsOfUmordhoth
          , EncounterSet.StrikingFear
          , EncounterSet.AncientEvils
          , EncounterSet.ChillingCold
          ]

        studyAberrantGateway <- genCard Locations.studyAberrantGateway
        let studyId = toLocationId studyAberrantGateway

        guestHall <- genCard Locations.guestHall
        bedroom <- genCard Locations.bedroom
        bathroom <- genCard Locations.bathroom

        pushAllEnd
          [ SetEncounterDeck encounterDeck
          , SetAgendaDeck
          , SetActDeck
          , PlaceLocation studyAberrantGateway
          , PlaceLocation guestHall
          , PlaceLocation bedroom
          , PlaceLocation bathroom
          , RevealLocation Nothing studyId
          , MoveAllTo (toSource attrs) studyId
          , story investigatorIds theGatheringIntro
          ]

        attic <- sample $ Locations.returnToAttic :| [Locations.attic]
        cellar <- sample $ Locations.returnToCellar :| [Locations.cellar]

        setAsideCards <- traverse
          genCard
          [ Enemies.ghoulPriest
          , Assets.litaChantler
          , attic
          , cellar
          , Locations.holeInTheWall
          , Locations.deepBelowYourHouse
          , Locations.farAboveYourHouse
          , Locations.parlor
          ]

        ReturnToTheGathering . TheGathering <$> runMessage
          msg
          (attrs
          & (setAsideCardsL .~ setAsideCards)
          & (actStackL
            . at 1
            ?~ [ Acts.mysteriousGateway
               , Acts.theBarrier
               , Acts.whatHaveYouDone
               ]
            )
          & (agendaStackL . at 1 ?~ theGatheringAgendaDeck)
          )
      _ -> ReturnToTheGathering <$> runMessage msg theGathering'
