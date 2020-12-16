{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Agenda.Cards.TheCloverClub
  ( TheCloverClub(..)
  , theCloverClub
  )
where

import Arkham.Import

import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Runner
import Arkham.Types.Game.Helpers
import Arkham.Types.Keyword
import Arkham.Types.Trait

newtype TheCloverClub = TheCloverClub Attrs
  deriving newtype (Show, ToJSON, FromJSON)

theCloverClub :: TheCloverClub
theCloverClub =
  TheCloverClub $ baseAttrs "02063" "The Clover Club" (Agenda 1 A) (Static 4)

instance HasActions env TheCloverClub where
  getActions i window (TheCloverClub x) = getActions i window x

instance HasSet Trait env EnemyId => HasModifiersFor env TheCloverClub where
  getModifiersFor _ (EnemyTarget eid) (TheCloverClub attrs) = do
    traits <- getSet eid
    pure $ toModifiers attrs [ AddKeyword Aloof | Criminal `member` traits ]
  getModifiersFor _ _ _ = pure []

instance AgendaRunner env => RunMessage env TheCloverClub where
  runMessage msg a@(TheCloverClub attrs@Attrs {..}) = case msg of
    InvestigatorDamageEnemy _ eid | agendaSequence == Agenda 1 A -> do
      traits <- getSet eid
      a <$ when
        (Criminal `member` traits)
        (unshiftMessage $ AdvanceAgenda agendaId)
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 A -> do
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      unshiftMessage $ Ask leadInvestigatorId (ChooseOne [AdvanceAgenda aid])
      pure
        $ TheCloverClub
        $ attrs
        & (sequenceL .~ Agenda 1 B)
        & (flippedL .~ True)
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 1 B -> do
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      completedExtracurricularActivity <-
        elem "02041" . map unCompletedScenarioId <$> getSetList ()

      let
        continueMessages =
          [ShuffleEncounterDiscardBackIn, NextAgenda aid "02064"]
            <> [ AdvanceCurrentAgenda | completedExtracurricularActivity ]

      unshiftMessage
        (Ask leadInvestigatorId $ ChooseOne [Label "Continue" continueMessages])
      pure $ TheCloverClub $ attrs & sequenceL .~ Agenda 1 B & flippedL .~ True
    _ -> TheCloverClub <$> runMessage msg attrs