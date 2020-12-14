module Arkham.Types.Agenda.Sequence where

import Arkham.Prelude

import Arkham.Types.AgendaId

agendaStep :: AgendaSequence -> AgendaStep
agendaStep (Agenda num _) = AgendaStep num

data AgendaSide = A | B
  deriving stock (Eq, Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data AgendaSequence = Agenda Int AgendaSide
  deriving stock (Eq, Show, Generic)
  deriving anyclass (ToJSON, FromJSON)