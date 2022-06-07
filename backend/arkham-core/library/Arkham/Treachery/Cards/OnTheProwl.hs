module Arkham.Treachery.Cards.OnTheProwl
  ( OnTheProwl(..)
  , onTheProwl
  ) where

import Arkham.Prelude

import Arkham.Scenarios.CurseOfTheRougarou.Helpers
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Classes
import Arkham.Message
import Arkham.Query
import Arkham.Target
import Arkham.Treachery.Runner
import Arkham.Treachery.Runner

newtype OnTheProwl = OnTheProwl TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

onTheProwl :: TreacheryCard OnTheProwl
onTheProwl = treachery OnTheProwl Cards.onTheProwl

instance TreacheryRunner env => RunMessage OnTheProwl where
  runMessage msg t@(OnTheProwl attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      mrougarou <- getTheRougarou
      t <$ case mrougarou of
        Nothing -> pure ()
        Just eid -> do
          locationIds <- setToList <$> nonBayouLocations
          locationsWithClueCounts <- for locationIds
            $ \lid -> (lid, ) . unClueCount <$> getCount lid
          let
            sortedLocationsWithClueCounts = sortOn snd locationsWithClueCounts
          case sortedLocationsWithClueCounts of
            [] -> pure ()
            ((_, c) : _) ->
              let
                (matches, _) =
                  span ((== c) . snd) sortedLocationsWithClueCounts
              in
                case matches of
                  [(x, _)] -> push (MoveUntil x (EnemyTarget eid))
                  xs ->
                    push
                      (chooseOne
                        iid
                        [ MoveUntil x (EnemyTarget eid) | (x, _) <- xs ]
                      )
    _ -> OnTheProwl <$> runMessage msg attrs
