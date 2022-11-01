module Arkham.Campaigns.TheForgottenAge.Helpers where

import Arkham.Prelude

import Arkham.Campaigns.TheForgottenAge.Supply
import Arkham.Card
import Arkham.Classes.HasQueue
import Arkham.Classes.Query
import Arkham.Deck
import Arkham.Game.Helpers
import Arkham.GameEnv
import Arkham.History
import Arkham.Id
import Arkham.Investigator.Types
import Arkham.Location.Types
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Scenario.Deck
import Arkham.Scenario.Types
import Arkham.Source
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Treachery.Cards qualified as Treacheries
import Arkham.Window ( Result (..), Window (..) )
import Arkham.Window qualified as Window

getHasSupply :: (HasGame m, Monad m) => InvestigatorId -> Supply -> m Bool
getHasSupply iid s = (> 0) <$> getSupplyCount iid s

getSupplyCount :: (HasGame m, Monad m) => InvestigatorId -> Supply -> m Int
getSupplyCount iid s =
  fieldMap InvestigatorSupplies (length . filter (== s)) iid

getAnyHasSupply :: (HasGame m, Monad m) => Supply -> m Bool
getAnyHasSupply = fmap notNull . getInvestigatorsWithSupply

getInvestigatorsWithSupply
  :: (HasGame m, Monad m) => Supply -> m [InvestigatorId]
getInvestigatorsWithSupply s =
  getInvestigatorIds >>= filterM (`getHasSupply` s)

getInvestigatorsWithoutSupply
  :: (HasGame m, Monad m) => Supply -> m [InvestigatorId]
getInvestigatorsWithoutSupply s =
  getInvestigatorIds >>= filterM (fmap not . (`getHasSupply` s))

getVengeanceInVictoryDisplay :: (HasCallStack, HasGame m, Monad m) => m Int
getVengeanceInVictoryDisplay = do
  inVictoryDisplay <-
    sum
    . map (fromMaybe 0 . cdVengeancePoints . toCardDef)
    <$> scenarioField ScenarioVictoryDisplay
  locationsWithModifier <- getSum <$> selectAgg
    (Sum . fromMaybe 0)
    LocationVengeance
    (LocationWithModifier InVictoryDisplayForCountingVengeance)
  pure $ inVictoryDisplay + locationsWithModifier

getExplorationDeck :: (HasGame m, Monad m) => m [Card]
getExplorationDeck = scenarioFieldMap
  ScenarioDecks
  (findWithDefault (error "missing deck") ExplorationDeck)

getSetAsidePoisonedCount :: (HasGame m, Monad m) => m Int
getSetAsidePoisonedCount = do
  n <- selectCount $ InDeckOf Anyone <> BasicCardMatch
    (cardIs Treacheries.poisoned)
  pure $ 4 - n

getIsPoisoned :: (HasGame m, Monad m) => InvestigatorId -> m Bool
getIsPoisoned iid =
  selectAny $ treacheryIs Treacheries.poisoned <> treacheryInThreatAreaOf iid

getSetAsidePoisoned :: (HasGame m, Monad m) => m Card
getSetAsidePoisoned =
  fromJustNote "not enough poison cards"
    . find ((== Treacheries.poisoned) . toCardDef)
    <$> scenarioField ScenarioSetAsideCards

data ExploreRule = PlaceExplored | ReplaceExplored
  deriving stock Eq

explore :: InvestigatorId -> Source -> CardMatcher -> ExploreRule -> GameT ()
explore iid source cardMatcher exploreRule = do
  explorationDeck <- getExplorationDeck
  canMove <- iid <=~> InvestigatorCanMove
  let
    cardMatcher' = CardWithOneOf [CardWithType TreacheryType, cardMatcher]
    (notMatched, matchedOnTop) =
      break (`cardMatch` cardMatcher') explorationDeck
  case matchedOnTop of
    [] -> do
      deck' <- shuffleM notMatched
      pushAll
        [ FocusCards notMatched
        , chooseOne
          iid
          [ Label
              "No Matches Found"
              [UnfocusCards, SetScenarioDeck ExplorationDeck deck']
          ]
        ]
    (x : xs) -> do
      msgs <- if cdCardType (toCardDef x) == LocationType
        then do
          let historyItem = mempty { historySuccessfulExplore = True }

          (locationAction, lid) <- case exploreRule of
            PlaceExplored -> pure (PlaceLocation x, toLocationId x)
            ReplaceExplored -> do
              let
                lSymbol = fromJustNote "no location symbol"
                  $ cdLocationRevealedSymbol (toCardDef x)
              mLocationToReplace <- selectOne $ LocationWithSymbol lSymbol
              case mLocationToReplace of
                Just lid -> pure (ReplaceLocation lid x, lid)
                Nothing -> error "no location found"

          afterPutIntoPlayWindow <- checkWindows
            [Window Timing.After (Window.PutLocationIntoPlay iid lid)]
          afterExploredWindow <- checkWindows
            [Window Timing.After $ Window.Explored iid (Success lid)]

          pure
            $ locationAction
            : [ MoveTo source iid lid
              | canMove && exploreRule == PlaceExplored
              ]
            <> [ UpdateHistory iid historyItem
               , afterExploredWindow
               , afterPutIntoPlayWindow
               ]
        else do
          windowMsg <- checkWindows
            [Window Timing.After $ Window.Explored iid Failure]
          pure
            [ DrewTreachery iid (Just $ ScenarioDeckByKey ExplorationDeck) x
            , windowMsg
            ]
      deck' <- if null notMatched then pure xs else shuffleM (xs <> notMatched)
      pushAll
        [ FocusCards (notMatched <> [x])
        , chooseOne
          iid
          [ TargetLabel
              (CardIdTarget $ toCardId x)
              (UnfocusCards : SetScenarioDeck ExplorationDeck deck' : msgs)
          ]
        ]
