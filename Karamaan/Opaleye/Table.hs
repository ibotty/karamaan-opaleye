{-# LANGUAGE FlexibleContexts #-}

module Karamaan.Opaleye.Table where

import Karamaan.Opaleye.QueryArr (Query, next, tagWith, simpleQueryArr)
import Database.HaskellDB.PrimQuery (PrimQuery(Project, BaseTable),
                                     PrimExpr(AttrExpr),
                                     Attribute, Assoc)
import Karamaan.Opaleye.TableColspec (TableColspec, TableColspecP,
                                      runWriterOfColspec, runPackMapOfColspec,
                                      tableColspecOfTableColspecP)
import Karamaan.Opaleye.Default (Default, def)
import Control.Arrow ((***))
import Karamaan.WhaleUtil ((.:))

makeTableDef :: Default TableColspecP a b => a -> String -> Query b
makeTableDef = makeTableQueryColspec def

makeTableQueryColspec :: TableColspecP a b -> a -> String -> Query b
makeTableQueryColspec = makeTable .: tableColspecOfTableColspecP

makeTable :: TableColspec a -> String -> Query a
makeTable colspec = makeTable' colspec (zip x x)
  where x = runWriterOfColspec colspec

makeTable' :: TableColspec a -> [(String, String)] -> String -> Query a
makeTable' colspec cols table_name = simpleQueryArr f
  where f ((), t0) = (retwires, primQuery, next t0)
          where (retwires, primQuery) = makeTable'' colspec cols table_name (tagWith t0)

-- TODO: this needs tidying
makeTable'' :: TableColspec a -> [(String, String)] -> String -> (String -> String)
               -> (a, PrimQuery)
makeTable'' colspec cols table_name tag' =
  let basetablecols :: [String]
      basetablecols = map snd cols
      makeAssoc :: (String, String) -> (Attribute, PrimExpr)
      makeAssoc = tag' *** AttrExpr
      projcols :: Assoc
      projcols = map makeAssoc cols
      q :: PrimQuery
      q = Project projcols (BaseTable table_name basetablecols)
  in (runPackMapOfColspec colspec tag', q)
