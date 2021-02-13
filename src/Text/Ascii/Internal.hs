{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ViewPatterns #-}

-- |
-- Module: Text.Ascii.Internal
-- Copyright: (C) 2021 Koz Ross
-- License: Apache 2.0
-- Maintainer: Koz Ross <koz.ross@retro-freedom.nz>
-- Stability: unstable, not subject to PVP
-- Portability: GHC only
--
-- This is an internal module, and is /not/ subject to the PVP. It can change
-- in any way, at any time, and should not be depended on unless you know
-- /exactly/ what you are doing. You have been warned.
module Text.Ascii.Internal where

import Control.DeepSeq (NFData)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import Data.CaseInsensitive (FoldCase (foldCase))
import Data.Char (chr, isAscii)
import Data.Coerce (coerce)
import Data.Hashable (Hashable)
import Data.Word (Word8)
import GHC.Exts (IsList (Item, fromList, fromListN, toList))
import Numeric (showHex)
import Optics.AffineTraversal (An_AffineTraversal, atraversal)
import Optics.At.Core (Index, IxValue, Ixed (IxKind, ix))
import Type.Reflection (Typeable)

-- | Represents valid ASCII characters, which are bytes from @0x00@ to @0x7f@.
--
-- @since 1.0.0
newtype AsciiChar = AsciiChar {toByte :: Word8}
  deriving
    ( -- | @since 1.0.0
      Eq,
      -- | @since 1.0.0
      Ord,
      -- | @since 1.0.0
      Hashable,
      -- | @since 1.0.0
      NFData
    )
    via Word8
  deriving stock
    ( -- | @since 1.0.0
      Typeable
    )

-- | @since 1.0.0
instance Show AsciiChar where
  {-# INLINEABLE show #-}
  show (AsciiChar w8) = "'0x" <> showHex w8 "'"

-- | @since 1.0.0
instance Bounded AsciiChar where
  {-# INLINEABLE minBound #-}
  minBound = AsciiChar 0
  {-# INLINEABLE maxBound #-}
  maxBound = AsciiChar 127

-- | @since 1.0.1
instance FoldCase AsciiChar where
  {-# INLINEABLE foldCase #-}
  foldCase ac@(AsciiChar w8)
    | 65 <= w8 && w8 <= 90 = AsciiChar (w8 + 32)
    | otherwise = ac

-- | View an 'AsciiChar' as its underlying byte. You can pattern match on this,
-- but since there are more bytes than valid ASCII characters, you cannot use
-- this to construct.
--
-- @since 1.0.0
pattern AsByte :: Word8 -> AsciiChar
pattern AsByte w8 <- AsciiChar w8

-- | View an 'AsciiChar' as a 'Char'. You can pattern match on this, but since
-- there are more 'Char's than valid ASCII characters, you cannot use this to
-- construct.
--
-- @since 1.0.0
pattern AsChar :: Char -> AsciiChar
pattern AsChar c <- AsciiChar (isJustAscii -> Just c)

{-# COMPLETE AsByte #-}

{-# COMPLETE AsChar #-}

-- | A string of ASCII characters, represented as a packed byte array.
--
-- @since 1.0.0
newtype AsciiText = AsciiText ByteString
  deriving
    ( -- | @since 1.0.0
      Eq,
      -- | @since 1.0.0
      Ord,
      -- | @since 1.0.0
      NFData,
      -- | @since 1.0.0
      Semigroup,
      -- | @since 1.0.0
      Monoid,
      -- | @since 1.0.0
      Show
    )
    via ByteString

-- | @since 1.0.0
instance IsList AsciiText where
  type Item AsciiText = AsciiChar
  {-# INLINEABLE fromList #-}
  fromList =
    coerce @ByteString @AsciiText
      . fromList
      . coerce @[AsciiChar] @[Word8]
  {-# INLINEABLE fromListN #-}
  fromListN n =
    coerce @ByteString @AsciiText
      . fromListN n
      . coerce @[AsciiChar] @[Word8]
  {-# INLINEABLE toList #-}
  toList = coerce . toList . coerce @AsciiText @ByteString

-- | @since 1.0.1
type instance Index AsciiText = Int

-- | @since 1.0.1
type instance IxValue AsciiText = AsciiChar

-- | @since 1.0.1
instance Ixed AsciiText where
  type IxKind AsciiText = An_AffineTraversal
  {-# INLINEABLE ix #-}
  ix i = atraversal get put
    where
      get :: AsciiText -> Either AsciiText AsciiChar
      get (AsciiText at) = case at BS.!? i of
        Nothing -> Left . AsciiText $ at
        Just w8 -> Right . AsciiChar $ w8
      put :: AsciiText -> AsciiChar -> AsciiText
      put (AsciiText at) (AsciiChar ac) = case BS.splitAt i at of
        (lead, end) -> case BS.uncons end of
          Nothing -> AsciiText at
          Just (_, end') -> AsciiText (lead <> BS.singleton ac <> end')

instance FoldCase AsciiText where
  {-# INLINEABLE foldCase #-}
  foldCase (AsciiText bs) = AsciiText . BS.map go $ bs
    where
      go :: Word8 -> Word8
      go w8
        | 65 <= w8 && w8 <= 90 = w8 + 32
        | otherwise = w8

-- Helpers

isJustAscii :: Word8 -> Maybe Char
isJustAscii w8 =
  if isAscii asChar
    then pure asChar
    else Nothing
  where
    asChar :: Char
    asChar = chr . fromIntegral $ w8
