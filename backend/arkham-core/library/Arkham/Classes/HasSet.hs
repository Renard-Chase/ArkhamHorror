module Arkham.Classes.HasSet where

import Arkham.Prelude

class (Hashable set, Eq set, Monad m) => HasSet set m a where
  getSet :: HasCallStack => a -> m (HashSet set)
  getSetList :: HasCallStack => a -> m [set]
  getSetList a = setToList <$> getSet a

getSetListMap
  :: HasSet set m a => (set -> set') -> a -> m [set']
getSetListMap f a = map f <$> getSetList a
