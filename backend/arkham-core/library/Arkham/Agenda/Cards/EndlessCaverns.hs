module Arkham.Agenda.Cards.EndlessCaverns
  ( EndlessCaverns(..)
  , endlessCaverns
  ) where

import Arkham.Prelude

import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Runner
import Arkham.Campaigns.TheForgottenAge.Helpers
import Arkham.Campaigns.TheForgottenAge.Supply
import Arkham.Classes
import Arkham.GameValue
import Arkham.Helpers.Query
import Arkham.Message
import Arkham.Scenarios.TheDepthsOfYoth.Helpers
import Arkham.SkillType
import Arkham.Target

newtype EndlessCaverns = EndlessCaverns AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

endlessCaverns :: AgendaCard EndlessCaverns
endlessCaverns = agenda (3, A) EndlessCaverns Cards.endlessCaverns (Static 4)

instance RunMessage EndlessCaverns where
  runMessage msg a@(EndlessCaverns attrs) = case msg of
    AdvanceAgenda aid | aid == toId attrs && onSide B attrs -> do
      enemyMsgs <- getPlacePursuitEnemyMessages
      lead <- getLeadInvestigatorId
      iids <- getInvestigatorIds
      pushAll
        $ enemyMsgs
        <> [ questionLabel "Choose a scout" lead $ ChooseOne
             [ targetLabel iid [HandleTargetChoice lead (toSource attrs) (InvestigatorTarget iid)]
             | iid <- iids
             ]
           , AdvanceAgendaDeck (agendaDeckId attrs) (toSource attrs)
           ]
      pure a
    HandleTargetChoice _ (isSource attrs -> True) (InvestigatorTarget iid) ->
      do
        hasRope <- getHasSupply iid Rope
        unless hasRope $ push $ chooseOne
          iid
          [ SkillLabel
            SkillCombat
            [ BeginSkillTest
                iid
                (toSource attrs)
                (toTarget attrs)
                Nothing
                SkillCombat
                5
            ]
          , SkillLabel
            SkillAgility
            [ BeginSkillTest
                iid
                (toSource attrs)
                (toTarget attrs)
                Nothing
                SkillAgility
                5
            ]
          ]
        pure a
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        push $ SufferTrauma iid 1 0
        pure a
    _ -> EndlessCaverns <$> runMessage msg attrs
