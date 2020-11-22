{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.SkillTest
  ( SkillTest(..)
  , SkillTestResult(..)
  , TokenResponse(..)
  , initSkillTest
  , skillTestToSource
  )
where

import Arkham.Import

import Arkham.Types.Action (Action)
import Arkham.Types.RequestedTokenStrategy
import Arkham.Types.SkillTestResult
import Arkham.Types.Stats
import Arkham.Types.TokenResponse
import qualified Data.HashMap.Strict as HashMap
import qualified Data.HashSet as HashSet
import Data.Semigroup
import Data.UUID.V4
import System.Environment

data SkillTest = SkillTest
  { skillTestInvestigator    :: InvestigatorId
  , skillTestSkillType :: SkillType
  , skillTestDifficulty      :: Int
  , skillTestSetAsideTokens  :: [Token]
  , skillTestRevealedTokens  :: [DrawnToken] -- tokens may change from physical representation
  , skillTestValueModifier :: Int
  , skillTestResult :: SkillTestResult
  , skillTestCommittedCards :: HashMap CardId (InvestigatorId, Card)
  , skillTestSource :: Source
  , skillTestTarget :: Target
  , skillTestAction :: Maybe Action
  , skillTestSubscribers :: [Target]
  }
  deriving stock (Show, Generic)

skillTestToSource :: SkillTest -> Source
skillTestToSource = toSource

instance Entity SkillTest where
  toSource SkillTest {..} =
    SkillTestSource skillTestInvestigator skillTestSource skillTestAction
  toTarget _ = SkillTestTarget
  isSource _ SkillTestSource{} = True
  isSource _ _ = False
  isTarget _ SkillTestTarget = True
  isTarget _ _ = False

instance ToJSON SkillTest where
  toJSON = genericToJSON $ aesonOptions $ Just "skillTest"
  toEncoding = genericToEncoding $ aesonOptions $ Just "skillTest"

instance FromJSON SkillTest where
  parseJSON = genericParseJSON $ aesonOptions $ Just "skillTest"

-- TODO: Cursed Swamp would apply to anyone trying to commit skill cards
instance HasModifiersFor env SkillTest where
  getModifiersFor = noModifiersFor

instance HasSet CommittedCardId env (InvestigatorId, SkillTest) where
  getSet (iid, st) =
    pure
      . HashSet.map CommittedCardId
      . keysSet
      . filterMap ((== iid) . fst)
      $ skillTestCommittedCards st

instance HasSet CommittedCardCode env SkillTest where
  getSet =
    pure
      . setFromList
      . map (CommittedCardCode . getCardCode . snd)
      . toList
      . skillTestCommittedCards

initSkillTest
  :: InvestigatorId
  -> Source
  -> Target
  -> Maybe Action
  -> SkillType
  -> Int
  -> Int
  -> SkillTest
initSkillTest iid source target maction skillType' _skillValue' difficulty' =
  SkillTest
    { skillTestInvestigator = iid
    , skillTestSkillType = skillType'
    , skillTestDifficulty = difficulty'
    , skillTestSetAsideTokens = mempty
    , skillTestRevealedTokens = mempty
    , skillTestValueModifier = 0
    , skillTestResult = Unrun
    , skillTestCommittedCards = mempty
    , skillTestSource = source
    , skillTestTarget = target
    , skillTestAction = maction
    , skillTestSubscribers = [InvestigatorTarget iid]
    }

subscribers :: Lens' SkillTest [Target]
subscribers =
  lens skillTestSubscribers $ \m x -> m { skillTestSubscribers = x }

valueModifier :: Lens' SkillTest Int
valueModifier =
  lens skillTestValueModifier $ \m x -> m { skillTestValueModifier = x }

setAsideTokens :: Lens' SkillTest [Token]
setAsideTokens =
  lens skillTestSetAsideTokens $ \m x -> m { skillTestSetAsideTokens = x }

revealedTokens :: Lens' SkillTest [DrawnToken]
revealedTokens =
  lens skillTestRevealedTokens $ \m x -> m { skillTestRevealedTokens = x }

committedCards :: Lens' SkillTest (HashMap CardId (InvestigatorId, Card))
committedCards =
  lens skillTestCommittedCards $ \m x -> m { skillTestCommittedCards = x }

result :: Lens' SkillTest SkillTestResult
result = lens skillTestResult $ \m x -> m { skillTestResult = x }

skillIconCount :: SkillTest -> Int
skillIconCount SkillTest {..} = length . filter matches $ concatMap
  (iconsForCard . snd)
  (toList skillTestCommittedCards)
 where
  iconsForCard (PlayerCard MkPlayerCard {..}) = pcSkills
  iconsForCard _ = []
  matches SkillWild = True
  matches s = s == skillTestSkillType

getModifiedSkillTestDifficulty
  :: (MonadReader env m, HasModifiersFor env ()) => SkillTest -> m Int
getModifiedSkillTestDifficulty s = do
  modifiers' <- getModifiersFor (toSource s) SkillTestTarget ()
  pure $ foldr applyModifier (skillTestDifficulty s) modifiers'
 where
  applyModifier (Difficulty m) n = max 0 (n + m)
  applyModifier _ n = n

type SkillTestRunner env
  = ( HasQueue env
    , HasCard InvestigatorId env
    , HasStats env (InvestigatorId, Maybe Action)
    , HasSource ForSkillTest env
    , HasModifiersFor env ()
    , HasTokenValue env ()
    , HasId LocationId env InvestigatorId
    , HasSet ConnectedLocationId env LocationId
    , HasSet InvestigatorId env ()
    )

-- per the FAQ the double negative modifier ceases to be active
-- when Sure Gamble is used so we overwrite both Negative and DoubleNegative
getModifiedTokenValue
  :: (MonadReader env m, HasModifiersFor env (), HasTokenValue env ())
  => SkillTest
  -> DrawnToken
  -> m Int
getModifiedTokenValue s t = do
  tokenModifiers' <- getModifiersFor (toSource s) (DrawnTokenTarget t) ()
  modifiedTokenFaces' <- getModifiedTokenFaces s t
  getSum . mconcat <$> for
    modifiedTokenFaces'
    (\tokenFace -> do
      baseTokenValue <- getTokenValue () (skillTestInvestigator s) tokenFace
      let
        updatedTokenValue =
          tokenValue $ foldr applyModifier baseTokenValue tokenModifiers'
      pure . Sum $ fromMaybe 0 updatedTokenValue
    )
 where
  applyModifier (ChangeTokenModifier modifier') (TokenValue token _) =
    TokenValue token modifier'
  applyModifier NegativeToPositive (TokenValue token (NegativeModifier n)) =
    TokenValue token (PositiveModifier n)
  applyModifier NegativeToPositive (TokenValue token (DoubleNegativeModifier n))
    = TokenValue token (PositiveModifier n)
  applyModifier DoubleNegativeModifiersOnTokens (TokenValue token (NegativeModifier n))
    = TokenValue token (DoubleNegativeModifier n)
  applyModifier (TokenValueModifier m) (TokenValue token (PositiveModifier n))
    = TokenValue token (PositiveModifier (max 0 (n + m)))
  applyModifier (TokenValueModifier m) (TokenValue token (NegativeModifier n))
    = TokenValue token (NegativeModifier (max 0 (n - m)))
  applyModifier _ currentTokenValue = currentTokenValue

-- really just looking for forced token changes here
getModifiedTokenFaces
  :: (HasModifiersFor env (), MonadReader env m)
  => SkillTest
  -> DrawnToken
  -> m [Token]
getModifiedTokenFaces s token = do
  tokenModifiers' <- getModifiersFor (toSource s) (DrawnTokenTarget token) ()
  pure $ foldr applyModifier [drawnTokenFace token] tokenModifiers'
 where
  applyModifier (ForcedTokenChange t ts) [t'] | t == t' = ts
  applyModifier _ ts = ts

instance SkillTestRunner env => RunMessage env SkillTest where
  runMessage msg s@SkillTest {..} = case msg of
    TriggerSkillTest iid -> do
      modifiers' <- getModifiersFor (toSource s) (InvestigatorTarget iid) ()
      if DoNotDrawChaosTokensForSkillChecks `elem` modifiers'
        then s <$ unshiftMessages
          [RunSkillTestSourceNotification iid skillTestSource, RunSkillTest iid]
        else s <$ unshiftMessages
          [RequestTokens (toSource s) iid 1 SetAside, RunSkillTest iid]
    DrawAnotherToken iid -> s <$ unshiftMessages
      [RequestTokens (toSource s) iid 1 SetAside, RunSkillTest iid]
    RequestedTokens (SkillTestSource siid source maction) iid tokenFaces -> do
      unshiftMessage (RevealSkillTestTokens iid)
      for_ tokenFaces $ \tokenFace -> do
        checkWindowMsgs <- checkWindows
          iid
          (\who -> pure [WhenRevealToken who tokenFace])
        unshiftMessages $ checkWindowMsgs <> resolve
          (RevealToken (SkillTestSource siid source maction) iid tokenFace)
      pure $ s & (setAsideTokens %~ (tokenFaces <>))
    RevealToken SkillTestSource{} _iid tokenFace -> do
      token' <- flip DrawnToken tokenFace . TokenId <$> liftIO nextRandom
      pure $ s & revealedTokens %~ (token' :)
    RevealSkillTestTokens iid -> do
      revealedTokenFaces <- concatMapM
        (\t -> map (t, ) <$> getModifiedTokenFaces s t)
        skillTestRevealedTokens
      unshiftMessages
        [ ResolveToken drawnToken tokenFace iid
        | (drawnToken, tokenFace) <- revealedTokenFaces
        ]
      pure
        $ s
        & (subscribers
          %~ (<> [ DrawnTokenTarget token'
                 | token' <- skillTestRevealedTokens
                 ]
             )
          )
    AddSkillTestSubscriber target -> pure $ s & subscribers %~ (target :)
    PassSkillTest -> do
      stats <- getStats (skillTestInvestigator, skillTestAction) (toSource s)
      let
        currentSkillValue = statsSkillValue stats skillTestSkillType
        modifiedSkillValue' =
          max 0 (currentSkillValue + skillTestValueModifier + skillIconCount s)
      unshiftMessages
        [ Ask skillTestInvestigator $ ChooseOne [SkillTestApplyResults]
        , SkillTestEnds
        ]
      pure $ s & result .~ SucceededBy True modifiedSkillValue'
    FailSkillTest -> do
      unshiftMessages
        $ [ Will
              (FailedSkillTest
                skillTestInvestigator
                skillTestAction
                skillTestSource
                target
                skillTestDifficulty
              )
          | target <- skillTestSubscribers
          ]
        <> [ Will
             (FailedSkillTest
               skillTestInvestigator
               skillTestAction
               skillTestSource
               (SkillTestInitiatorTarget skillTestTarget)
               skillTestDifficulty
             )
           , Ask skillTestInvestigator $ ChooseOne [SkillTestApplyResults]
           , SkillTestEnds
           ]
      pure $ s & result .~ FailedBy True skillTestDifficulty
    StartSkillTest _ -> s <$ unshiftMessages
      (HashMap.foldMapWithKey
          (\k (i, _) -> [CommitCard i k])
          skillTestCommittedCards
      <> [TriggerSkillTest skillTestInvestigator]
      )
    InvestigatorCommittedSkill _ skillId -> do
      pure $ s & subscribers %~ (SkillTarget skillId :)
    SkillTestCommitCard iid cardId -> do
      card <- asks (getCard iid cardId)
      pure $ s & committedCards %~ insertMap cardId (iid, card)
    SkillTestUncommitCard _ cardId ->
      pure $ s & committedCards %~ deleteMap cardId
    ReturnSkillTestRevealedTokens -> do
      -- Rex's Curse timing keeps effects on stack so we do
      -- not want to remove them as subscribers from the stack
      unshiftMessage $ ResetTokens (toSource s)
      pure $ s & setAsideTokens .~ mempty & revealedTokens .~ mempty
    SkillTestEnds -> s <$ unshiftMessage (ResetTokens (toSource s))
    SkillTestResults -> do
      unshiftMessage
        (Ask skillTestInvestigator $ ChooseOne [SkillTestApplyResults])
      case skillTestResult of
        SucceededBy _ n -> unshiftMessages
          ([ Will
               (PassedSkillTest
                 skillTestInvestigator
                 skillTestAction
                 skillTestSource
                 target
                 n
               )
           | target <- skillTestSubscribers
           ]
          <> [ Will
                 (PassedSkillTest
                   skillTestInvestigator
                   skillTestAction
                   skillTestSource
                   (SkillTestInitiatorTarget skillTestTarget)
                   n
                 )
             ]
          )
        FailedBy _ n -> unshiftMessages
          ([ Will
               (FailedSkillTest
                 skillTestInvestigator
                 skillTestAction
                 skillTestSource
                 target
                 n
               )
           | target <- skillTestSubscribers
           ]
          <> [ Will
                 (FailedSkillTest
                   skillTestInvestigator
                   skillTestAction
                   skillTestSource
                   (SkillTestInitiatorTarget skillTestTarget)
                   n
                 )
             ]
          )
        Unrun -> pure ()
      pure s
    SkillTestApplyResultsAfter -> do -- ST.7 -- apply results
      unshiftMessage SkillTestEnds -- -> ST.8 -- Skill test ends

      case skillTestResult of
        SucceededBy _ n -> unshiftMessages
          ([ After
               (PassedSkillTest
                 skillTestInvestigator
                 skillTestAction
                 skillTestSource
                 target
                 n
               )
           | target <- skillTestSubscribers
           ]
          <> [ After
                 (PassedSkillTest
                   skillTestInvestigator
                   skillTestAction
                   skillTestSource
                   (SkillTestInitiatorTarget skillTestTarget)
                   n
                 )
             ]
          )
        FailedBy _ n -> unshiftMessages
          ([ After
               (FailedSkillTest
                 skillTestInvestigator
                 skillTestAction
                 skillTestSource
                 target
                 n
               )
           | target <- skillTestSubscribers
           ]
          <> [ After
                 (FailedSkillTest
                   skillTestInvestigator
                   skillTestAction
                   skillTestSource
                   (SkillTestInitiatorTarget skillTestTarget)
                   n
                 )
             ]
          )
        Unrun -> pure ()
      pure s
    SkillTestApplyResults -> do -- ST.7 Apply Results
      unshiftMessage SkillTestApplyResultsAfter
      s <$ case skillTestResult of
        SucceededBy _ n -> unshiftMessages
          ([ PassedSkillTest
               skillTestInvestigator
               skillTestAction
               skillTestSource
               target
               n
           | target <- skillTestSubscribers
           ]
          <> [ PassedSkillTest
                 skillTestInvestigator
                 skillTestAction
                 skillTestSource
                 (SkillTestInitiatorTarget skillTestTarget)
                 n
             ]
          )
        FailedBy _ n -> unshiftMessages
          ([ FailedSkillTest
               skillTestInvestigator
               skillTestAction
               skillTestSource
               target
               n
           | target <- skillTestSubscribers
           ]
          <> [ FailedSkillTest
                 skillTestInvestigator
                 skillTestAction
                 skillTestSource
                 (SkillTestInitiatorTarget skillTestTarget)
                 n
             ]
          )
        Unrun -> pure ()
    RerunSkillTest -> do
      case skillTestResult of
        FailedBy True _ -> pure s
        _ -> do
          withQueue $ \queue ->
            let
              queue' = flip filter queue $ \case
                Will FailedSkillTest{} -> False
                Will PassedSkillTest{} -> False
                CheckWindow _ [WhenWouldFailSkillTest _] -> False
                Ask skillTestInvestigator' (ChooseOne [SkillTestApplyResults])
                  | skillTestInvestigator == skillTestInvestigator' -> False
                _ -> True
            in (queue', ())
          s <$ unshiftMessage (RunSkillTest skillTestInvestigator)
    RunSkillTest _ -> do
      tokenValues <- sum
        <$> for skillTestRevealedTokens (getModifiedTokenValue s)
      stats <- getStats (skillTestInvestigator, skillTestAction) (toSource s)
      modifiedSkillTestDifficulty <- getModifiedSkillTestDifficulty s
      let
        currentSkillValue = statsSkillValue stats skillTestSkillType
        totaledTokenValues = tokenValues + skillTestValueModifier
        modifiedSkillValue' =
          max 0 (currentSkillValue + totaledTokenValues + skillIconCount s)
      unshiftMessage SkillTestResults
      liftIO $ whenM
        (isJust <$> lookupEnv "DEBUG")
        (putStrLn
        . pack
        $ "skill value: "
        <> show currentSkillValue
        <> "\n+ totaled token values: "
        <> show totaledTokenValues
        <> "\n+ skill icon count: "
        <> show (skillIconCount s)
        <> "\n-------------------------"
        <> "\n= Modified skill value: "
        <> show modifiedSkillValue'
        <> "\nDifficulty: "
        <> show skillTestDifficulty
        <> "\nModified Skill Difficulty: "
        <> show modifiedSkillTestDifficulty
        )
      if modifiedSkillValue' >= modifiedSkillTestDifficulty
        then
          pure
          $ s
          & (result .~ SucceededBy
              False
              (modifiedSkillValue' - modifiedSkillTestDifficulty)
            )
          & (valueModifier .~ totaledTokenValues)
        else
          pure
          $ s
          & (result .~ FailedBy
              False
              (modifiedSkillTestDifficulty - modifiedSkillValue')
            )
          & (valueModifier .~ totaledTokenValues)
    _ -> pure s
