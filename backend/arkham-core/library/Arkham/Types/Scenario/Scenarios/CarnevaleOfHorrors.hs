module Arkham.Types.Scenario.Scenarios.CarnevaleOfHorrors
  ( CarnevaleOfHorrors(..)
  , carnevaleOfHorrors
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Assets
import qualified Arkham.Enemy.Cards as Enemies
import qualified Arkham.Location.Cards as Locations
import Arkham.PlayerCard
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Difficulty
import Arkham.Types.Direction
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Id
import Arkham.Types.LocationMatcher
import Arkham.Types.Message
import Arkham.Types.Scenario.Attrs
import Arkham.Types.Scenario.Helpers
import Arkham.Types.Scenario.Runner
import Arkham.Types.Token
import qualified Data.List.NonEmpty as NE

newtype CarnevaleOfHorrors = CarnevaleOfHorrors ScenarioAttrs
  deriving stock Generic
  deriving anyclass HasRecord
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

carnevaleOfHorrors :: Difficulty -> CarnevaleOfHorrors
carnevaleOfHorrors difficulty = CarnevaleOfHorrors $ (baseAttrs
                                                       "82001"
                                                       "Carnevale of Horrors"
                                                       [ "82002"
                                                       , "82003"
                                                       , "82004"
                                                       ]
                                                       [ "82005"
                                                       , "82006"
                                                       , "82007"
                                                       ]
                                                       difficulty
                                                     )
  { scenarioLocationLayout = Just
    [ ".         .         .         location1 .         .         ."
    , ".         location8 location8 location1 location2 location2 ."
    , ".         location8 location8 .         location2 location2 ."
    , "location7 location7 .         .         .         location3 location3"
    , ".         location6 location6 .         location4 location4 ."
    , ".         location6 location6 location5 location4 location4 ."
    , ".         .         .         location5 .         .         ."
    ]
  }

instance HasTokenValue env InvestigatorId => HasTokenValue env CarnevaleOfHorrors where
  getTokenValue (CarnevaleOfHorrors attrs) iid = \case
    Skull -> pure $ TokenValue Skull (NegativeModifier 2) -- TODO: innocent reveler count
    Cultist -> pure $ TokenValue Cultist NoModifier
    Tablet -> pure $ toTokenValue attrs Tablet 3 4
    ElderThing -> pure $ toTokenValue attrs ElderThing 4 6
    otherFace -> getTokenValue attrs iid otherFace

instance (HasId (Maybe LocationId) env LocationMatcher, ScenarioRunner env) => RunMessage env CarnevaleOfHorrors where
  runMessage msg s@(CarnevaleOfHorrors attrs) = case msg of
    Setup -> do
      investigatorIds <- getInvestigatorIds

      -- Encounter Deck
      encounterDeck <- buildEncounterDeckExcluding
        [ Enemies.donLagorio
        , Enemies.elisabettaMagro
        , Enemies.salvatoreNeri
        , Enemies.savioCorvi
        , Enemies.cnidathqua
        ]
        [EncounterSet.CarnevaleOfHorrors]

      -- Locations
      let locationLabels = [ "location" <> tshow @Int n | n <- [1 .. 8] ]
      randomLocations <- drop 1 <$> shuffleM
        [ Locations.streetsOfVenice
        , Locations.rialtoBridge
        , Locations.venetianGarden
        , Locations.bridgeOfSighs
        , Locations.floodedSquare
        , Locations.accademiaBridge
        , Locations.theGuardian
        ]
      sanMarcoBasilicaId <- getRandom
      unshuffled <- zip <$> getRandoms <*> pure
        (Locations.canalSide : randomLocations)
      let nonSanMarcoBasilicaLocationIds = map fst unshuffled
      locationIdsWithMaskedCarnevaleGoers <-
        zip nonSanMarcoBasilicaLocationIds
          <$> (shuffleM =<< traverse
                (fmap PlayerCard . genPlayerCard)
                [ Assets.maskedCarnevaleGoer_17
                , Assets.maskedCarnevaleGoer_18
                , Assets.maskedCarnevaleGoer_19
                , Assets.maskedCarnevaleGoer_20
                , Assets.maskedCarnevaleGoer_21
                , Assets.maskedCarnevaleGoer_21
                , Assets.maskedCarnevaleGoer_21
                ]
              )
      locations <- ((sanMarcoBasilicaId, Locations.sanMarcoBasilica) :|)
        <$> shuffleM unshuffled

      -- Assets
      abbess <- PlayerCard <$> genPlayerCard Assets.abbessAllegriaDiBiase

      pushAllEnd
        $ [SetEncounterDeck encounterDeck, AddAgenda "82002", AddAct "82005"]
        <> [ PlaceLocation locationId cardDef
           | (locationId, cardDef) <- toList locations
           ]
        <> [ SetLocationLabel locationId label
           | (label, (locationId, _)) <- zip locationLabels (toList locations)
           ]
        <> [ PlacedLocationDirection lid1 LeftOf lid2
           | ((lid1, _), (lid2, _)) <- zip
             (toList locations)
             (drop 1 $ toList locations)
           ]
        <> [ PlacedLocationDirection
               (fst $ NE.last locations)
               LeftOf
               (fst $ NE.head locations)
           ]
        <> [ CreateStoryAssetAt asset locationId
           | (locationId, asset) <- locationIdsWithMaskedCarnevaleGoers
           ]
        <> [ CreateStoryAssetAt abbess sanMarcoBasilicaId
           , RevealLocation Nothing sanMarcoBasilicaId
           , MoveAllTo sanMarcoBasilicaId
           , AskMap
           . mapFromList
           $ [ ( iid
               , ChooseOne
                 [ Run
                     [ Continue "Continue"
                     , FlavorText
                       (Just "The Carnevale is Coming...")
                       [ "\"Look,\" Sheriff Engel insists, \"I know it sounds crazy, but that's\
                       \ all there is to it.\" He sighs and sits back down, pouring a cup of joe\
                       \ for you and one for himself. \"A dame in Uptown spotted a cracked egg\
                       \ wearing this mask and holdin' a bloody butcher's cleaver,\" he says,\
                       \ motioning to the black leather mask sitting on his desk. It has a comically\
                       \ long nose and a strange symbol scrawled in yellow on its forehead. \"So, she\
                       \ calls it in. My boys and I picked him up on the corner of Saltonstall &\
                       \ Garrison.\" The sheriff\'s jaw clenches and his brows furrow as he recounts\
                       \ the story. \"Fella did nothing but laugh as we slapped the bracelets on him.\
                       \ Called himself Zanni. Said nothing except the 'carnival is coming,' whatever\
                       \ the hell that meant. Wasn't until the next day we found the victim's body.\
                       \ Defense wanted him in a straitjacket. We were happy to oblige.\""
                       , "There isn't much time to spare. If your research is right, there is more to\
                       \ this case than meets the eye. This \"Zanni\" wasn't talking about Darke's\
                       \ Carnival, but rather, the Carnevale of Venice, which begins just before the\
                       \ next full moon..."
                       ]
                     ]
                 ]
               )
             | iid <- investigatorIds
             ]
           ]

      let
        locations' = locationNameMap
          [ Locations.sanMarcoBasilica
          , Locations.canalSide
          , Locations.streetsOfVenice
          , Locations.rialtoBridge
          , Locations.venetianGarden
          , Locations.bridgeOfSighs
          , Locations.floodedSquare
          , Locations.accademiaBridge
          , Locations.theGuardian
          ]
      CarnevaleOfHorrors <$> runMessage msg (attrs & locationsL .~ locations')
    SetTokensForScenario -> do
      let
        tokens = if isEasyStandard attrs
          then
            [ PlusOne
            , Zero
            , Zero
            , Zero
            , MinusOne
            , MinusOne
            , MinusOne
            , MinusTwo
            , MinusThree
            , MinusFour
            , MinusSix
            , Skull
            , Skull
            , Skull
            , Cultist
            , Tablet
            , ElderThing
            , AutoFail
            , ElderSign
            ]
          else
            [ PlusOne
            , Zero
            , Zero
            , Zero
            , MinusOne
            , MinusOne
            , MinusThree
            , MinusFour
            , MinusFive
            , MinusSix
            , MinusSeven
            , Skull
            , Skull
            , Skull
            , Cultist
            , Tablet
            , ElderThing
            , AutoFail
            , ElderSign
            ]
      s <$ push (SetTokens tokens)
    _ -> CarnevaleOfHorrors <$> runMessage msg attrs