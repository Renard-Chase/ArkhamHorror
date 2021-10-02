module Arkham.Types.Event.Cards.WingingIt
  ( wingingIt
  , WingingIt(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Helpers
import Arkham.Types.Event.Runner
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype WingingIt = WingingIt EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wingingIt :: EventCard WingingIt
wingingIt = event WingingIt Cards.wingingIt

instance EventRunner env => RunMessage env WingingIt where
  runMessage msg e@(WingingIt attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ | eid == toId attrs -> do
      lid <- getId iid
      e <$ pushAll
        [ skillTestModifier attrs (LocationTarget lid) (ShroudModifier (-1))
        , Investigate iid lid (toSource attrs) Nothing SkillIntellect False
        , Discard (toTarget attrs)
        ]
    _ -> WingingIt <$> runMessage msg attrs