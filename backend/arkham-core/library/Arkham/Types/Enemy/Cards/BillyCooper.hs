{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Cards.BillyCooper where

import Arkham.Import

import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner
import Arkham.Types.Trait

newtype BillyCooper = BillyCooper Attrs
  deriving newtype (Show, ToJSON, FromJSON)

billyCooper :: EnemyId -> BillyCooper
billyCooper uuid =
  BillyCooper
    $ baseAttrs uuid "50045"
    $ (healthDamage .~ 2)
    . (fight .~ 5)
    . (health .~ Static 4)
    . (evade .~ 2)
    . (unique .~ True)

instance HasModifiersFor env BillyCooper where
  getModifiersFor = noModifiersFor

instance HasModifiers env BillyCooper where
  getModifiers _ (BillyCooper Attrs {..}) =
    pure . concat . toList $ enemyModifiers

instance ActionRunner env => HasActions env BillyCooper where
  getActions iid window (BillyCooper attrs) = getActions iid window attrs

instance (EnemyRunner env) => RunMessage env BillyCooper where
  runMessage msg e@(BillyCooper attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId ->
      e <$ spawnAt (Just iid) eid "Easttown"
    After (EnemyDefeated _ _ lid _ _ traits)
      | lid == enemyLocation && Monster `elem` traits -> do
        e <$ unshiftMessage (AddToVictory $ toTarget attrs)
    _ -> BillyCooper <$> runMessage msg attrs
