{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Text.Ascii
  ( -- * Type
    AsciiText,

    -- * Creation
    empty,
    singleton,
    ascii,

    -- * Basic interface
    cons,
    snoc,
    uncons,
    unsnoc,
    length,

    -- * Transformations
    map,
    intercalate,
    intersperse,
    transpose,
    reverse,

    -- * Folds
    foldl,
    foldl',
    foldr,
    foldr',

    -- ** Special folds
    concat,
    concatMap,

    -- * Construction

    -- ** Scans
    scanl,
    scanr,

    -- ** Accumulating maps
    mapAccumL,
    mapAccumR,

    -- ** Generation and unfolding
    unfoldr,
    unfoldrN,

    -- * Substrings

    -- ** Breaking strings
    take,
    drop,
    takeWhile,
    takeWhileEnd,
    dropWhile,
    dropWhileEnd,
    splitAt,
    break,
    span,
    group,
    groupBy,
    inits,
    tails,

    -- ** Breaking into many substrings
    split,

    -- ** Breaking into lines and words

    -- * View patterns
    stripPrefix,
    stripSuffix,

    -- * Searching
    filter,
    find,
    partition,

    -- * Indexing
    findIndex,

    -- * Zipping
    zip,

    -- * Conversions
    fromText,
    fromByteString,
    toText,
    toByteString,

    -- * Optics
    textWise,
    byteStringWise,
  )
where

import Control.Category ((.))
import Data.Bifunctor (first)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import Data.Char (isAscii)
import Data.Coerce (coerce)
import Data.Maybe (Maybe (Just, Nothing))
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import Optics.Prism (Prism', prism')
import Text.Ascii.Internal (AsciiChar (AsciiChar), AsciiText (AsciiText))
import Text.Ascii.QQ (ascii)
import Prelude
  ( Bool,
    Int,
    not,
    pure,
    ($),
    (<$>),
    (>),
  )

-- Note on pragmata
--
-- This is cribbed directly from bytestring, as I figure they know what they're
-- doing way better than we do. When we add our own functionality, this probably
-- needs to be considered more carefully. - Koz

-- Creation

-- $setup
-- >>> :set -XNoImplicitPrelude
-- >>> :set -XQuasiQuotes
-- >>> import Text.Ascii
-- >>> import Text.Ascii.Char (char, upcase)
-- >>> import Prelude ((.), ($), replicate, (<>))
-- >>> import Data.Maybe (fromMaybe)

-- | The empty text.
--
-- >>> empty
-- ""
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
empty :: AsciiText
empty = coerce BS.empty

-- | A text consisting of a single ASCII character.
--
-- >>> singleton [char| 'w' |]
-- "w"
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
{-# INLINE [1] singleton #-}
singleton :: AsciiChar -> AsciiText
singleton = coerce BS.singleton

-- Basic interface

-- | Adds a character to the front of a text. This requires copying, which gives
-- its complexity.
--
-- >>> cons [char| 'n' |] [ascii| "eko" |]
-- "neko"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE cons #-}
cons :: AsciiChar -> AsciiText -> AsciiText
cons = coerce BS.cons

-- | Adds a character to the back of a text. This requires copying, which gives
-- its complexity.
--
-- >>> snoc [ascii| "nek" |] [char| 'o' |]
-- "neko"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE snoc #-}
snoc :: AsciiText -> AsciiChar -> AsciiText
snoc = coerce BS.snoc

-- | If the argument is non-empty, gives 'Just' the first character and the
-- rest, and 'Nothing' otherwise.
--
-- >>> uncons empty
-- Nothing
-- >>> uncons . singleton $ [char| 'w' |]
-- Just ('0x77',"")
-- >>> uncons [ascii| "nekomimi" |]
-- Just ('0x6e',"ekomimi")
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
{-# INLINE uncons #-}
uncons :: AsciiText -> Maybe (AsciiChar, AsciiText)
uncons = coerce BS.uncons

-- | If the argument is non-empty, gives 'Just' the initial segment and the last
-- character, and 'Nothing' otherwise.
--
-- >>> unsnoc empty
-- Nothing
-- >>> unsnoc . singleton $ [char| 'w' |]
-- Just ("",'0x77')
-- >>> unsnoc [ascii| "catboy" |]
-- Just ("catbo",'0x79')
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
{-# INLINE unsnoc #-}
unsnoc :: AsciiText -> Maybe (AsciiText, AsciiChar)
unsnoc = coerce BS.unsnoc

-- | The number of characters (and, since this is ASCII, bytes) in the text.
--
-- >>> length . singleton $ [char| 'w' |]
-- 1
-- >>> length [ascii| "nyan nyan" |]
-- 9
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
{-# INLINE length #-}
length :: AsciiText -> Int
length = coerce BS.length

-- Transformations

-- | Copy, and apply the function to each element of, the text.
--
-- >>> map (\c -> fromMaybe c . upcase $ c) [ascii| "nyan!" |]
-- "NYAN!"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE map #-}
map :: (AsciiChar -> AsciiChar) -> AsciiText -> AsciiText
map = coerce BS.map

-- | Takes a text and a list of texts, and concatenates the list after
-- interspersing the first argument between each element of the list.
--
-- >>> intercalate [ascii| " ~ " |] []
-- ""
-- >>> intercalate [ascii| " ~ " |] [[ascii| "nyan" |]]
-- "nyan"
-- >>> intercalate [ascii| " ~ " |] . replicate 3 $ [ascii| "nyan" |]
-- "nyan ~ nyan ~ nyan"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE [1] intercalate #-}
intercalate :: AsciiText -> [AsciiText] -> AsciiText
intercalate = coerce BS.intercalate

-- | Takes a character, and places it between the characters of a text.
--
-- >>> intersperse [char| '~' |] empty
-- ""
-- >>> intersperse [char| '~' |] . singleton $ [char| 'w' |]
-- "w"
-- >>> intersperse [char| '~' |] [ascii| "nyan" |]
-- "n~y~a~n"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
intersperse :: AsciiChar -> AsciiText -> AsciiText
intersperse = coerce BS.intersperse

-- | Transpose the rows and columns of the argument. This uses
-- 'Data.List.transpose' internally, and thus, isn't very efficient.
--
-- >>> transpose []
-- []
-- >>> transpose [[ascii| "w" |]]
-- ["w"]
-- >>> transpose [[ascii| "nyan" |]]
-- ["n","y","a","n"]
-- >>> transpose . replicate 3 $ [ascii| "nyan" |]
-- ["nnn","yyy","aaa","nnn"]
-- >>> transpose [[ascii| "cat" |], [ascii| "boy" |], [ascii| "nyan" |]]
-- ["cbn","aoy","tya","n"]
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
transpose :: [AsciiText] -> [AsciiText]
transpose = coerce BS.transpose

-- | Reverse the text.
--
-- >>> reverse empty
-- ""
-- >>> reverse . singleton $ [char| 'w' |]
-- "w"
-- >>> reverse [ascii| "catboy goes nyan" |]
-- "nayn seog yobtac"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
reverse :: AsciiText -> AsciiText
reverse = coerce BS.reverse

-- TODO: Replace, justifyLeft, justifyRight, center

-- Folds

-- | Left-associative fold of a text.
--
-- >>> foldl (\acc c -> [ascii| "f(" |] <> acc <> singleton c <> [ascii| ")" |]) [ascii| "a" |] [ascii| "catboy" |]
-- "f(f(f(f(f(f(ac)a)t)b)o)y)"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE foldl #-}
foldl :: (a -> AsciiChar -> a) -> a -> AsciiText -> a
foldl f x (AsciiText bs) = BS.foldl (coerce f) x bs

-- | Left-associative fold of a text, strict in the accumulator.
--
-- >>> foldl' (\acc c -> [ascii| "f(" |] <> acc <> singleton c <> [ascii| ")" |]) [ascii| "a" |] [ascii| "catboy" |]
-- "f(f(f(f(f(f(ac)a)t)b)o)y)"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE foldl' #-}
foldl' :: (a -> AsciiChar -> a) -> a -> AsciiText -> a
foldl' f x (AsciiText bs) = BS.foldl' (coerce f) x bs

-- | Right-associative fold of a text.
--
-- >>> foldr (\c acc -> [ascii| "f(" |] <> acc <> singleton c <> [ascii| ")" |]) [ascii| "a" |] [ascii| "catboy" |]
-- "f(f(f(f(f(f(ay)o)b)t)a)c)"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE foldr #-}
foldr :: (AsciiChar -> a -> a) -> a -> AsciiText -> a
foldr f x (AsciiText bs) = BS.foldr (coerce f) x bs

-- | Right-associative fold of a text, strict in the accumulator.
--
-- >>> foldr' (\c acc -> [ascii| "f(" |] <> acc <> singleton c <> [ascii| ")" |]) [ascii| "a" |] [ascii| "catboy" |]
-- "f(f(f(f(f(f(ay)o)b)t)a)c)"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE foldr' #-}
foldr' :: (AsciiChar -> a -> a) -> a -> AsciiText -> a
foldr' f x (AsciiText bs) = BS.foldr' (coerce f) x bs

-- Special folds

-- | Concatenate a list of texts.
--
-- >>> concat []
-- ""
-- >>> concat [[ascii| "catboy" |]]
-- "catboy"
-- >>> concat . replicate 4 $ [ascii| "nyan" |]
-- "nyannyannyannyan"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
concat :: [AsciiText] -> AsciiText
concat = coerce BS.concat

-- TODO: Generalize concat. No reason not to have it work with an arbitrary
-- Foldable. - Koz

-- | Map a text-producing function over a text, then concatenate the results.
--
-- >>> concatMap singleton empty
-- ""
-- >>> concatMap singleton [ascii| "nyan" |]
-- "nyan"
-- >>> concatMap (\c -> singleton c <> singleton c) [ascii| "nekomimi" |]
-- "nneekkoommiimmii"
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
concatMap :: (AsciiChar -> AsciiText) -> AsciiText -> AsciiText
concatMap = coerce BS.concatMap

-- TODO: Generalize concatMap. There's no reason it can't project to an
-- arbitrary Monoid, because it's just doing list smashing in the backend. - Koz

-- | 'scanl' is similar to 'foldl', but returns a list of successive values from
-- the left.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE scanl #-}
scanl ::
  -- | accumulator -> element -> new accumulator
  (AsciiChar -> AsciiChar -> AsciiChar) ->
  -- | Starting accumulator value
  AsciiChar ->
  -- | Input of length \(n\)
  AsciiText ->
  -- | Output of length \(n + 1\)
  AsciiText
scanl = coerce BS.scanl

-- | 'scanr' is similar to 'foldr', but returns a list of successive values from
-- the right.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE scanr #-}
scanr ::
  -- | element -> accumulator -> new accumulator
  (AsciiChar -> AsciiChar -> AsciiChar) ->
  -- | Starting accumulator value
  AsciiChar ->
  -- | Input of length \(n\)
  AsciiText ->
  -- | Output of length \(n + 1\)
  AsciiText
scanr = coerce BS.scanr

-- Accumulating maps

-- | Like a combination of 'map' and 'foldl''. Applies a function to each
-- element of an 'AsciiText', passing an accumulating parameter from left to
-- right, and returns a final 'AsciiText' along with the accumulating
-- parameter's final value.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE mapAccumL #-}
mapAccumL :: (a -> AsciiChar -> (a, AsciiChar)) -> a -> AsciiText -> (a, AsciiText)
mapAccumL f x (AsciiText bs) = AsciiText <$> BS.mapAccumL (coerce f) x bs

-- | Like a combination of 'map' and 'foldr'. Applies a function to each element
-- of an 'AsciiText', passing an accumulating parameter from right to left, and
-- returns a final 'AsciiText' along with the accumulating parameter's final
-- value.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE mapAccumR #-}
mapAccumR :: (a -> AsciiChar -> (a, AsciiChar)) -> a -> AsciiText -> (a, AsciiText)
mapAccumR f x (AsciiText bs) = AsciiText <$> BS.mapAccumL (coerce f) x bs

-- Generation and unfolding

-- TODO: replicate

-- | Similar to 'Data.List.unfoldr'. The function parameter takes a seed value,
-- and produces either 'Nothing' (indicating that we're done) or 'Just' an
-- 'AsciiChar' and a new seed value. 'unfoldr' then, given a starting seed, will
-- repeatedly call the function parameter on successive seed values, returning
-- the resulting 'AsciiText', based on the 'AsciiChar's produced, in the same
-- order.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE unfoldr #-}
unfoldr :: (a -> Maybe (AsciiChar, a)) -> a -> AsciiText
unfoldr f = AsciiText . BS.unfoldr (coerce f)

-- | Similar to 'unfoldr', but also takes a maximum length parameter. The second
-- element of the result tuple will be 'Nothing' if we finished with the
-- function argument returning 'Nothing', and 'Just' the final seed value if we
-- reached the maximum length before that happened.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE unfoldrN #-}
unfoldrN :: Int -> (a -> Maybe (AsciiChar, a)) -> a -> (AsciiText, Maybe a)
unfoldrN n f = first AsciiText . BS.unfoldrN n (coerce f)

-- | @take n t@ returns the prefix of @t@ with length
-- \(\min \{ \max \{ 0, {\tt n}\}, {\tt length} \; {\tt t} \}\)
--
-- >>> take (-100) [ascii| "catboy" |]
-- ""
-- >>> take 0 [ascii| "catboy" |]
-- ""
-- >>> take 3 [ascii| "catboy" |]
-- "cat"
-- >>> take 1000 [ascii| "catboy" |]
-- "catboy"
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
{-# INLINE take #-}
take :: Int -> AsciiText -> AsciiText
take = coerce BS.take

-- TODO: takeEnd

-- | @drop n t@ returns the suffix of @t@ with length
-- \(\max \{ 0, \min \{ {\tt length} \; {\tt t}, {\tt length} \; {\tt t} - {\tt n} \} \}\)
--
-- >>> drop (-100) [ascii| "catboy" |]
-- "catboy"
-- >>> drop 0 [ascii| "catboy" |]
-- "catboy"
-- >>> drop 3 [ascii| "catboy" |]
-- "boy"
-- >>> drop 1000 [ascii| "catboy" |]
-- ""
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
{-# INLINE drop #-}
drop :: Int -> AsciiText -> AsciiText
drop = coerce BS.drop

-- TODO: dropEnd

-- | @takeWhile p t@ returns the longest prefix of @t@ of characters that
-- satisfy @p@.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE [1] takeWhile #-}
takeWhile :: (AsciiChar -> Bool) -> AsciiText -> AsciiText
takeWhile f (AsciiText at) = AsciiText . BS.takeWhile (coerce f) $ at

-- | @takeWhileEnd p t@ returns the longest suffix of @t@ of characters that
-- satisfy @p@. Equivalent to @'reverse' . 'takeWhile' p . 'reverse'@.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE takeWhileEnd #-}
takeWhileEnd :: (AsciiChar -> Bool) -> AsciiText -> AsciiText
takeWhileEnd f = AsciiText . BS.takeWhileEnd (coerce f) . coerce

-- | @dropWhile p t@ returns the suffix remaining after @'takeWhile' p t@.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE [1] dropWhile #-}
dropWhile :: (AsciiChar -> Bool) -> AsciiText -> AsciiText
dropWhile f (AsciiText at) = AsciiText . BS.dropWhile (coerce f) $ at

-- | @dropWhileEnd p t@ returns the prefix remaining after @'takeWhileEnd' p t@.
-- Equivalent to @'reverse' . 'dropWhile' p . 'reverse'@.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE dropWhileEnd #-}
dropWhileEnd :: (AsciiChar -> Bool) -> AsciiText -> AsciiText
dropWhileEnd f = AsciiText . BS.dropWhileEnd (coerce f) . coerce

-- TODO: dropAround, strip, stripStart, stripEnd

-- | @splitAt n t@ is equivalent to @('take' n t, 'drop' n t)@.
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
{-# INLINE splitAt #-}
splitAt :: Int -> AsciiText -> (AsciiText, AsciiText)
splitAt = coerce BS.splitAt

-- TODO: breakOn, breakOnEnd

-- | @break p t@ is equivalent to @('takeWhile' ('not' p) t, 'dropWhile' ('not'
-- p) t)@.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
break :: (AsciiChar -> Bool) -> AsciiText -> (AsciiText, AsciiText)
break = coerce BS.break

-- | @span p t@ is equivalent to @('takeWhile' p t, 'dropWhile' p t)@.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE [1] span #-}
span :: (AsciiChar -> Bool) -> AsciiText -> (AsciiText, AsciiText)
span = coerce BS.span

-- | Separate a text into a list of texts such that:
--
-- * Their concatenation is equal to the original argument; and
-- * Equal adjacent characters in the original argument are in the same text in
-- the result.
--
-- This is a specialized form of 'groupBy', and is about 40% faster than
-- @'groupBy' '=='@.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
group :: AsciiText -> [AsciiText]
group = coerce BS.group

-- | Separate a text into a list of texts such that:
--
-- * Their concatenation is equal to the original argument; and
-- * Adjacent characters for which the function argument returns @True@ are in
-- the same text in the result.
--
-- 'group' is a special case for the function argument '=='; it is also about
-- 40% faster.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
groupBy :: (AsciiChar -> AsciiChar -> Bool) -> AsciiText -> [AsciiText]
groupBy = coerce BS.groupBy

-- | All prefixes of the argument, from shortest to longest.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
inits :: AsciiText -> [AsciiText]
inits = coerce BS.inits

-- | All suffixes of the argument, from shortest to longest.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
tails :: AsciiText -> [AsciiText]
tails = coerce BS.tails

-- Breaking into many substrings

-- TODO: splitOn

-- | @split p t@ separates @t@ into components delimited by separators, for
-- which @p@ returns @True@. The results do not contain the separators. Multiple
-- adjacent separators result in an empty component.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
{-# INLINE split #-}
split :: (AsciiChar -> Bool) -> AsciiText -> [AsciiText]
split = coerce BS.splitWith

-- TODO: chunksOf
-- Breaking into lines and words
-- TODO: lines, words, unlines, unwords

-- View patterns

-- | Return 'Just' the suffix of the second text if it has the first text as
-- a prefix, 'Nothing' otherwise.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
stripPrefix :: AsciiText -> AsciiText -> Maybe AsciiText
stripPrefix = coerce BS.stripPrefix

-- | Return 'Just' the prefix of the second text if it has the first text as
-- a suffix, 'Nothing' otherwise.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
stripSuffix :: AsciiText -> AsciiText -> Maybe AsciiText
stripSuffix = coerce BS.stripSuffix

-- TODO: stripInfix, commonPrefixes

-- Searching

-- | Return the text comprised of all the characters that satisfy the function
-- argument (that is, for which it returns 'True'), in the same order as in the
-- original.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
filter :: (AsciiChar -> Bool) -> AsciiText -> AsciiText
filter = coerce BS.filter

-- TODO: breakOnAll

-- | Returns 'Just' the first character in the text satisfying the predicate,
-- 'Nothing' otherwise.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
find :: (AsciiChar -> Bool) -> AsciiText -> Maybe AsciiChar
find = coerce BS.find

-- | @partition p t@ is equivalent to @('filter' p t, 'filter' ('not' p) t)@.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
partition :: (AsciiChar -> Bool) -> AsciiText -> (AsciiText, AsciiText)
partition = coerce BS.partition

-- Indexing

-- TODO: index, safe only

-- | Returns 'Just' the first index in the text such that the character at that
-- index satisfies the predicate, 'Nothing' otherwise.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
findIndex :: (AsciiChar -> Bool) -> AsciiText -> Maybe Int
findIndex = coerce BS.findIndex

-- TODO: count

-- Zipping

zip :: AsciiText -> AsciiText -> [(AsciiChar, AsciiChar)]
zip = coerce BS.zip

-- TODO: zipWith

-- Conversions

-- | Try and convert a 'Text' into an 'AsciiText'. Gives 'Nothing' if the 'Text'
-- contains any symbols which lack an ASCII equivalent.
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
fromText :: Text -> Maybe AsciiText
fromText t = case T.find (not . isAscii) t of
  Nothing -> pure . AsciiText . encodeUtf8 $ t
  Just _ -> Nothing

-- | Try and convert a 'ByteString' into an 'AsciiText'. Gives 'Nothing' if the
-- 'ByteString' contains any bytes outside the ASCII range (that is, from 0 to
-- 127 inclusive).
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
fromByteString :: ByteString -> Maybe AsciiText
fromByteString bs = case BS.find (> 127) bs of
  Nothing -> pure . AsciiText $ bs
  Just _ -> Nothing

-- | Convert an 'AsciiText' into a 'Text' (by copying).
--
-- /Complexity:/ \(\Theta(n)\)
--
-- @since 1.0.0
toText :: AsciiText -> Text
toText (AsciiText bs) = decodeUtf8 bs

-- | Reinterpret an 'AsciiText' as a 'ByteString' (without copying).
--
-- /Complexity:/ \(\Theta(1)\)
--
-- @since 1.0.0
toByteString :: AsciiText -> ByteString
toByteString = coerce

-- Prisms

-- | A convenient demonstration of the relationship between 'toText' and
-- 'fromText'.
--
-- @since 1.0.0
textWise :: Prism' Text AsciiText
textWise = prism' toText fromText

-- | A convenient demonstration of the relationship between 'toByteString' and
-- 'fromByteString'.
--
-- @since 1.0.0
byteStringWise :: Prism' ByteString AsciiText
byteStringWise = prism' toByteString fromByteString
