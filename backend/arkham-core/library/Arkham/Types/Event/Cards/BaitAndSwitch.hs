{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Event.Cards.BaitAndSwitch where

import Arkham.Json
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.EventId
import Arkham.Types.InvestigatorId
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Lens.Micro

import ClassyPrelude

newtype BaitAndSwitch = BaitAndSwitch Attrs
  deriving newtype (Show, ToJSON, FromJSON)

baitAndSwitch :: InvestigatorId -> EventId -> BaitAndSwitch
baitAndSwitch iid uuid = BaitAndSwitch $ baseAttrs iid uuid "02034"

instance HasActions env investigator BaitAndSwitch where
  getActions i window (BaitAndSwitch attrs) = getActions i window attrs

instance (EventRunner env) => RunMessage env BaitAndSwitch where
  runMessage msg e@(BaitAndSwitch attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> do
      unshiftMessages
        [ ChooseEvadeEnemy iid (EventSource eid) SkillWillpower [] [] [] False
        , Discard (EventTarget eid)
        ]
      BaitAndSwitch <$> runMessage msg (attrs & resolved .~ True)
    PassedSkillTest iid _ (EventSource eid) SkillTestInitiatorTarget _
      | eid == eventId -> do
        lid <- asks (getId iid)
        connectedLocationIds <- map unConnectedLocationId . setToList <$> asks
          (getSet lid)
        EnemyTarget enemyId <- fromMaybe (error "missing target")
          <$> asks (getTarget ForSkillTest)
        unless (null connectedLocationIds) $ do
          withQueue $ \queue ->
            let
              (before, rest) = break
                (\case
                  AfterEvadeEnemy{} -> True
                  _ -> False
                )
                queue
            in
              case rest of
                (x : xs) ->
                  ( before
                    <> [ x
                       , Ask
                         iid
                         (ChooseOne
                           [ EnemyMove enemyId lid lid'
                           | lid' <- connectedLocationIds
                           ]
                         )
                       ]
                    <> xs
                  , ()
                  )
                _ -> error "evade missing"

        pure e
    _ -> BaitAndSwitch <$> runMessage msg attrs