{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Treachery.Cards.ArcaneBarrier
  ( ArcaneBarrier(..)
  , arcaneBarrier
  )
where

import Arkham.Import

import Arkham.Types.Treachery.Attrs
import Arkham.Types.Treachery.Runner

newtype ArcaneBarrier = ArcaneBarrier Attrs
  deriving newtype (Show, ToJSON, FromJSON)

arcaneBarrier :: TreacheryId -> a -> ArcaneBarrier
arcaneBarrier uuid _ = ArcaneBarrier $ baseAttrs uuid "02102"

instance HasModifiersFor env ArcaneBarrier where
  getModifiersFor = noModifiersFor

instance HasActions env ArcaneBarrier where
  getActions i window (ArcaneBarrier attrs) = getActions i window attrs

instance TreacheryRunner env => RunMessage env ArcaneBarrier where
  runMessage msg t@(ArcaneBarrier attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      lid <- getId iid
      t <$ unshiftMessage (AttachTreachery (toId attrs) (LocationTarget lid))
    Will (MoveTo iid lid) -> do
      investigatorLocation <- getId iid
      when
          (treacheryOnLocation lid attrs
          || treacheryOnLocation investigatorLocation attrs
          )
        $ do
            moveFromMessage <- fromJustNote "missing move from" <$> popMessage
            moveToMessage <- fromJustNote "missing move to" <$> popMessage
            unshiftMessage
              (CreateEffect
                (CardCode "02102")
                (Just (EffectMessages [moveFromMessage, moveToMessage]))
                (toSource attrs)
                (InvestigatorTarget iid)
              )
      pure t
    _ -> ArcaneBarrier <$> runMessage msg attrs