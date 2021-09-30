module Arkham.Types.Effect.Effects.Mesmerize
  ( Mesmerize(..)
  , mesmerize
  ) where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Assets
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Effect.Attrs
import Arkham.Types.Id
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Target

newtype Mesmerize = Mesmerize EffectAttrs
  deriving anyclass HasAbilities
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

mesmerize :: EffectArgs -> Mesmerize
mesmerize = Mesmerize . uncurry4 (baseAttrs "82035")

instance HasModifiersFor env Mesmerize

instance
  ( HasSet FarthestLocationId env (InvestigatorId, LocationMatcher)
  , HasQueue env
  )
  => RunMessage env Mesmerize where
  runMessage msg e@(Mesmerize attrs) = case msg of
    Flipped _ card -> do
      if toCardDef card == Assets.innocentReveler
        then do
          let aid = AssetId $ toCardId card
          case effectTarget attrs of
            InvestigatorTarget iid -> do
              locationTargets <- map (LocationTarget . unFarthestLocationId)
                <$> getSetList (iid, LocationWithoutInvestigators)
              e <$ pushAll
                [ chooseOne
                  iid
                  [ TargetLabel locationTarget [AttachAsset aid locationTarget]
                  | locationTarget <- locationTargets
                  ]
                , AssetDamage aid (effectSource attrs) 1 1
                , DisableEffect $ toId attrs
                ]
            _ -> error "Must be investigator target"
        else e <$ push (DisableEffect $ toId attrs)
    _ -> Mesmerize <$> runMessage msg attrs