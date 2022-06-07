module Arkham.Location.Cards.AdministrationOffice_131
  ( administrationOffice_131
  , AdministrationOffice_131(..)
  ) where

import Arkham.Prelude

import Arkham.Location.Cards qualified as Cards (administrationOffice_131)
import Arkham.Classes
import Arkham.GameValue
import Arkham.Investigator.Attrs (Field(..))
import Arkham.Location.Runner
import Arkham.Location.Helpers
import Arkham.Modifier
import Arkham.Projection
import Arkham.Source

newtype AdministrationOffice_131 = AdministrationOffice_131 LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

administrationOffice_131 :: LocationCard AdministrationOffice_131
administrationOffice_131 = location
  AdministrationOffice_131
  Cards.administrationOffice_131
  2
  (PerPlayer 2)
  Triangle
  [Square]

instance HasModifiersFor AdministrationOffice_131 where
  getModifiersFor (InvestigatorSource iid) target (AdministrationOffice_131 attrs)
    | isTarget attrs target
    = do
      cardsInHand <- fieldMap InvestigatorHand length iid
      pure $ toModifiers attrs [ CannotInvestigate | cardsInHand <= 4 ]
  getModifiersFor _ _ _ = pure []

instance RunMessage AdministrationOffice_131 where
  runMessage msg (AdministrationOffice_131 attrs) =
    AdministrationOffice_131 <$> runMessage msg attrs
