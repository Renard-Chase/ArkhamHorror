module Arkham.Types.Event.Cards.WillToSurvive3 where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Message
import Arkham.Types.Target

newtype WillToSurvive3 = WillToSurvive3 EventAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

willToSurvive3 :: EventCard WillToSurvive3
willToSurvive3 = event WillToSurvive3 Cards.willToSurvive3

instance HasModifiersFor env WillToSurvive3 where
  getModifiersFor = noModifiersFor

instance HasActions env WillToSurvive3 where
  getActions i window (WillToSurvive3 attrs) = getActions i window attrs

instance HasQueue env => RunMessage env WillToSurvive3 where
  runMessage msg e@(WillToSurvive3 attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      e <$ pushAll
        [ CreateEffect "01085" Nothing (toSource attrs) (InvestigatorTarget iid)
        , Discard (EventTarget eid)
        ]
    _ -> WillToSurvive3 <$> runMessage msg attrs