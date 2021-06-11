module Arkham.Types.Event.Cards.SecondWind
  ( secondWind
  , SecondWind(..)
  )
where

import Arkham.Prelude

import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.EventId
import Arkham.Types.InvestigatorId
import Arkham.Types.Message
import Arkham.Types.Query
import Arkham.Types.Target
import Arkham.Types.Window

newtype SecondWind = SecondWind EventAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

secondWind :: InvestigatorId -> EventId -> SecondWind
secondWind iid uuid = SecondWind $ baseAttrs iid uuid "04149"

instance HasCount ActionTakenCount env InvestigatorId => HasActions env SecondWind where
  getActions iid (InHandWindow ownerId (DuringTurn You)) (SecondWind attrs)
    | iid == ownerId = do
      actionsTaken <- unActionTakenCount <$> getCount iid
      pure
        [ InitiatePlayCard iid (getCardId attrs) Nothing True
        | actionsTaken == 0
        ]
  getActions iid window (SecondWind attrs) = getActions iid window attrs

instance HasModifiersFor env SecondWind where
  getModifiersFor = noModifiersFor

instance (HasQueue env, HasRoundHistory env) => RunMessage env SecondWind where
  runMessage msg e@(SecondWind attrs@EventAttrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      roundHistory <- getRoundHistory
      let
        didDrawTreachery = \case
          DrewTreachery iid' _ -> iid == iid'
          _ -> False
        damageToHeal = if any didDrawTreachery roundHistory then 2 else 1
      e <$ unshiftMessages
        [ HealDamage (InvestigatorTarget iid) damageToHeal
        , DrawCards iid 1 False
        , Discard (toTarget attrs)
        ]
    _ -> SecondWind <$> runMessage msg attrs
