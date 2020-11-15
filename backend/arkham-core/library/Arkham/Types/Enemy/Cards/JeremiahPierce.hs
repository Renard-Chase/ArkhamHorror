{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Cards.JeremiahPierce where

import Arkham.Import

import Arkham.Types.Action hiding (Ability)
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner

newtype JeremiahPierce = JeremiahPierce Attrs
  deriving newtype (Show, ToJSON, FromJSON)

jeremiahPierce :: EnemyId -> JeremiahPierce
jeremiahPierce uuid =
  JeremiahPierce
    $ baseAttrs uuid "50044"
    $ (healthDamage .~ 1)
    . (sanityDamage .~ 1)
    . (fight .~ 4)
    . (health .~ Static 3)
    . (evade .~ 4)
    . (unique .~ True)

instance HasModifiersFor env JeremiahPierce where
  getModifiersFor = noModifiersFor

instance HasModifiers env JeremiahPierce where
  getModifiers _ (JeremiahPierce Attrs {..}) =
    pure . concat . toList $ enemyModifiers

instance ActionRunner env => HasActions env JeremiahPierce where
  getActions iid NonFast (JeremiahPierce attrs@Attrs {..}) = do
    baseActions <- getActions iid NonFast attrs
    locationId <- asks $ getId @LocationId iid
    pure
      $ baseActions
      <> [ ActivateCardAbilityAction
             iid
             (mkAbility (EnemySource enemyId) 1 (ActionAbility 1 (Just Parley)))
         | locationId == enemyLocation
         ]
  getActions _ _ _ = pure []

instance (EnemyRunner env) => RunMessage env JeremiahPierce where
  runMessage msg e@(JeremiahPierce attrs@Attrs {..}) = case msg of
    InvestigatorDrawEnemy iid _ eid | eid == enemyId -> do
      myourHouse <- asks $ getId @(Maybe LocationId) (LocationName "Your House")
      let spawnLocation = maybe "Rivertown" (const "Your House") myourHouse
      e <$ spawnAt (Just iid) eid spawnLocation
    UseCardAbility iid (EnemySource eid) _ 1 | eid == enemyId ->
      e <$ unshiftMessages
        [ AddToVictory (EnemyTarget enemyId)
        , CreateEffect (toSource attrs) (InvestigatorTarget iid) enemyCardCode
        ]
    _ -> JeremiahPierce <$> runMessage msg attrs