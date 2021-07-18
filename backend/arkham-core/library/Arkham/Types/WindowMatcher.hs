module Arkham.Types.WindowMatcher where

import Arkham.Prelude

import Arkham.Types.Trait

data WindowMatcher
  = AfterEnemyDefeated Who WindowEnemyMatcher
  | FastPlayerWindow Who
  | OrWindowMatcher [WindowMatcher]
  | DealtDamageOrHorror Who
  | WhenDrawEncounterCard Who EncounterCardMatcher
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON, Hashable)

data EncounterCardMatcher = NonWeakness
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON, Hashable)

newtype WindowEnemyMatcher = EnemyWithTrait Trait
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON, Hashable)

type Who = WindowInvestigatorMatcher

data WindowInvestigatorMatcher = You | Anyone
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON, Hashable)