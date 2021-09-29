module Arkham.Types.Event.Cards.PreparedForTheWorst
  ( preparedForTheWorst
  , PreparedForTheWorst(..)
  ) where

import Arkham.Prelude

import Arkham.Event.Cards qualified as Cards
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Message
import Arkham.Types.Target
import Arkham.Types.Trait
import Arkham.Types.Zone

newtype PreparedForTheWorst = PreparedForTheWorst EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor env, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

preparedForTheWorst :: EventCard PreparedForTheWorst
preparedForTheWorst = event PreparedForTheWorst Cards.preparedForTheWorst

instance RunMessage env PreparedForTheWorst where
  runMessage msg e@(PreparedForTheWorst attrs) = case msg of
    InvestigatorPlayEvent iid eid _ _ | eid == toId attrs -> do
      e <$ pushAll
        [ Search
          iid
          (toSource attrs)
          (InvestigatorTarget iid)
          (FromTopOfDeck 9)
          [Weapon]
          (ShuffleBackIn $ DrawFound iid)
        , Discard (toTarget attrs)
        ]
    _ -> PreparedForTheWorst <$> runMessage msg attrs
