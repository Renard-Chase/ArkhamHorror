module Arkham.Types.Treachery.Cards.Atychiphobia
  ( atychiphobia
  , Atychiphobia(..)
  ) where

import Arkham.Prelude

import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.TreacheryId
import Arkham.Types.Window


import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype Atychiphobia = Atychiphobia TreacheryAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

atychiphobia :: TreacheryId -> Maybe InvestigatorId -> Atychiphobia
atychiphobia uuid iid = Atychiphobia $ weaknessAttrs uuid iid "60504"

instance HasModifiersFor env Atychiphobia where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Atychiphobia where
  getActions iid NonFast (Atychiphobia a) =
    withTreacheryInvestigator a $ \tormented -> do
      investigatorLocationId <- getId @LocationId iid
      treacheryLocation <- getId tormented
      pure
        [ ActivateCardAbilityAction
            iid
            (mkAbility (toSource a) 1 (ActionAbility Nothing $ ActionCost 2))
        | treacheryLocation == investigatorLocationId
        ]
  getActions _ _ _ = pure []

instance (TreacheryRunner env) => RunMessage env Atychiphobia where
  runMessage msg t@(Atychiphobia attrs@TreacheryAttrs {..}) = case msg of
    Revelation iid source | isSource attrs source ->
      t <$ unshiftMessage (AttachTreachery treacheryId $ InvestigatorTarget iid)
    FailedSkillTest iid _ _ _ _ _ | treacheryOnInvestigator iid attrs ->
      t <$ unshiftMessage
        (InvestigatorAssignDamage
          iid
          (TreacherySource treacheryId)
          DamageAny
          0
          1
        )
    UseCardAbility _ (TreacherySource tid) _ 1 _ | tid == treacheryId ->
      t <$ unshiftMessage (Discard (TreacheryTarget treacheryId))
    _ -> Atychiphobia <$> runMessage msg attrs
