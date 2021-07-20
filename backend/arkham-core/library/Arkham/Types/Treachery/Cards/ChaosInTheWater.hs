module Arkham.Types.Treachery.Cards.ChaosInTheWater
  ( chaosInTheWater
  , ChaosInTheWater(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Assets
import qualified Arkham.Treachery.Cards as Cards
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Id
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype ChaosInTheWater = ChaosInTheWater TreacheryAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

chaosInTheWater :: TreacheryCard ChaosInTheWater
chaosInTheWater = treachery ChaosInTheWater Cards.chaosInTheWater

instance HasModifiersFor env ChaosInTheWater

instance HasActions env ChaosInTheWater where
  getActions i window (ChaosInTheWater attrs) = getActions i window attrs

instance
  ( HasId (Maybe OwnerId) env AssetId
  , HasSet AssetId env (InvestigatorId, CardDef)
  , TreacheryRunner env
  )
  => RunMessage env ChaosInTheWater where
  runMessage msg t@(ChaosInTheWater attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      innocentRevelerIds <- getSetList @AssetId (iid, Assets.innocentReveler)
      investigatorsWithRevelers <-
        catMaybes
          <$> traverse (fmap (fmap unOwnerId) . getId) innocentRevelerIds
      t <$ pushAll
        ([ RevelationSkillTest iid' source SkillAgility 4
         | iid' <- nub (iid : investigatorsWithRevelers)
         ]
        <> [Discard (toTarget attrs)]
        )
    FailedSkillTest iid _ source SkillTestInitiatorTarget{} _ _
      | isSource attrs source -> do
        t <$ push
          (InvestigatorAssignDamage
            iid
            source
            (DamageFirst Assets.innocentReveler)
            1
            0
          )
    _ -> ChaosInTheWater <$> runMessage msg attrs