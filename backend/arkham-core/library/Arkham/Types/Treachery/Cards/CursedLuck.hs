module Arkham.Types.Treachery.Cards.CursedLuck
  ( CursedLuck(..)
  , cursedLuck
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Criteria
import Arkham.Types.GameValue
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Source
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Helpers
import Arkham.Types.Treachery.Runner

newtype CursedLuck = CursedLuck TreacheryAttrs
  deriving anyclass IsTreachery
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

cursedLuck :: TreacheryCard CursedLuck
cursedLuck = treachery CursedLuck Cards.cursedLuck

instance HasModifiersFor env CursedLuck where
  getModifiersFor SkillTestSource{} (InvestigatorTarget iid) (CursedLuck attrs)
    = pure $ toModifiers
      attrs
      [ AnySkillValue (-1) | treacheryOnInvestigator iid attrs ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities env CursedLuck where
  getAbilities _ _ (CursedLuck x) = pure
    [ restrictedAbility x 1 (InThreatAreaOf You)
      $ ForcedAbility
      $ SkillTestResult Timing.After You AnySkillTest
      $ SuccessResult
      $ AtLeast
      $ Static 1
    ]

instance TreacheryRunner env => RunMessage env CursedLuck where
  runMessage msg t@(CursedLuck attrs) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ push (AttachTreachery (toId attrs) (InvestigatorTarget iid))
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      t <$ push (Discard $ toTarget attrs)
    _ -> CursedLuck <$> runMessage msg attrs
