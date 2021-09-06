module Arkham.Types.Treachery.Cards.SpiritsTorment
  ( spiritsTorment
  , SpiritsTorment(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Target
import qualified Arkham.Types.Timing as Timing
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype SpiritsTorment = SpiritsTorment TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

spiritsTorment :: TreacheryCard SpiritsTorment
spiritsTorment = treachery SpiritsTorment Cards.spiritsTorment

instance HasAbilities SpiritsTorment where
  getAbilities (SpiritsTorment a) =
    [ mkAbility a 1
      $ ForcedAbility
      $ Leaves Timing.When You
      $ LocationWithTreachery
      $ TreacheryWithId
      $ toId a
    , restrictedAbility a 2 OnSameLocation $ ActionAbility Nothing $ Costs
      [ActionCost 1, PlaceClueOnLocationCost 1]
    ]

instance TreacheryRunner env => RunMessage env SpiritsTorment where
  runMessage msg t@(SpiritsTorment attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      lid <- getId iid
      t <$ push (AttachTreachery (toId attrs) (LocationTarget lid))
    UseCardAbility iid source _ 1 _ | isSource attrs source -> t <$ push
      (chooseOne
        iid
        [ Label
          "Take 1 horror"
          [InvestigatorAssignDamage iid source DamageAny 0 1]
        , Label "Lose 1 action" [LoseActions iid source 1]
        ]
      )
    UseCardAbility _ source _ 2 _ | isSource attrs source ->
      t <$ push (Discard $ toTarget attrs)
    _ -> SpiritsTorment <$> runMessage msg attrs