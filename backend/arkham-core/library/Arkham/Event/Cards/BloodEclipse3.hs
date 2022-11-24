module Arkham.Event.Cards.BloodEclipse3
  ( bloodEclipse3
  , BloodEclipse3(..)
  ) where

import Arkham.Prelude

import Arkham.Card
import Arkham.Classes
import Arkham.Cost
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Helpers.Modifiers
import Arkham.Message
import Arkham.SkillType
import Arkham.Target

newtype BloodEclipse3 = BloodEclipse3 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

bloodEclipse3 :: EventCard BloodEclipse3
bloodEclipse3 = event BloodEclipse3 Cards.bloodEclipse3

countDamage :: Payment -> Int
countDamage = \case
  InvestigatorDamagePayment n -> n
  Payments ps -> sum $ map countDamage ps
  _ -> 0

instance RunMessage BloodEclipse3 where
  runMessage msg e@(BloodEclipse3 attrs) = case msg of
    PaidForCardCost iid card (countDamage -> n)
      | toCardId card == toCardId attrs -> do
        pushAll
          [ skillTestModifiers
            (toSource attrs)
            (InvestigatorTarget iid)
            [DamageDealt n, SkillModifier SkillWillpower n]
          , ChooseFightEnemy
            iid
            (toSource attrs)
            Nothing
            SkillWillpower
            mempty
            False
          , Discard (toTarget attrs)
          ]
        pure e
    _ -> BloodEclipse3 <$> runMessage msg attrs