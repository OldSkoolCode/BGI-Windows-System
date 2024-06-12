'
'    Abstract
'    --------
'
'    Double hashing is a useful method for data compression when
'    it is necessary to search for strings previously encountered
'    in the uncompressed data.  Double hashing performs better than
'    linear probing when the hash table gets full, and is usually
'    faster than linked lists.
'
'
'    Description
'    -----------
'
'    This double hashing method is in Power BASIC v 1.1 which
'    supports modulus arithmetic on long and quad integers.
'    The code was translated from the pseudo Pascal source code in
'
'		 Robert Sedgewick.  ALGORITHMS.  Addison-Wesley.
'		 1983 ed.  pp 203/10.
'
'    and was modified to hash 32 K items into a table size of
'    32 K entries, occupying about 64 K RAM for the table.
'
'    Of incidental interest to the method are the following lists
'    of prime numbers near to but not exceeding the base-2 boundaries
'    of 8 K, 16 K, 32 K, and 64 K.  (See the textbook for why.)
'
'        8101,  8111,  8117,  8123,  8147,  8161,  8171,  8179,  8191
'
'       16301, 16319, 16333, 16339, 16349, 16361, 16363, 16369, 16381
'
'       32693, 32707, 32713, 32717, 32719, 32749
'
'       65497, 65519, 65521
'
'
'    For more details and other data compression material, contact:
'
'    Colin James III, CQA
'    Certified Quality Analyst
'    1975 Oak St, #4
'    Lakewood, CO  80215-2737
'
'    DATA:  (303) 234 - 0085  CEC Services BBS, 9600 V.32c MNP 9, 8-N-1
'
'            Specializing in: data compression, Ada, BASIC,
'                             SQA/SQC, and DoD-STD-2167A
'
'            New callers may download the public catalog list
'            of files (occupying about 130 MB of over 2 GB).
'
'            Subscription for general access is $ 10 per month.
'
'            Specialty access to compression source code is $150
'            per month where a significant, two-pass improvement on
'            LZW has been developed as LZJ, is now available, and
'            when a generalized mathematical description is completed
'            is due to be patented as an unique apparatus.
'            (LZJ compresses about 15 % better than the products now
'            available;  speed is relatively faster in the PC model.)
'
'            Please note:
'            CEC Services can NOT be reached on either of the
'            major computer services, only at the number above.
'
'    VOICE: (303) 234 - 0084  ( 4 PM to 8 PM Mountain Time  O N L Y )
'
' ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
'
' Double-Hash  v 02
' -----------
'
' Copr 1990, Colin James III  All Rights Reserved
'	     Permission to copy is hereby granted

' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
' set up data type definitions
' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DEFINT I                               ' define I for      integers
DEFLNG L                               ' define L for long integers


' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
' set up Lempel-Ziv [ LZ ] table data structure
' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DIM I.LZ.prefix ( 0: 32766)            ' LZ codes are broken into prefix
				       '    codes or sequence numbers of
				       '    15-bits ( 0 ... 32766)
DIM I.LZ.suffix ( 0: 32766)            ' and suffix codes or input bytes
				       '    following the prefix
'
' Two integer arrays are used due to the single array size limitation of
' 64 K in Power BASIC (the successor to Turbo BASIC).  Indexing is the
' same in the respective arrays.  The sequential codes entered into the
' arrays could of course be output as variable length codes as the method
' Lempel-Ziv-Welch or LZW.  (The variable code would be the prefix only,
' followed by an 8-bit byte suffix.)  These arrays are necessary to have
' below for checking a hash hit.  As Sedgewick notes, a hash table which
' is about 90% full can take 50 compares for a linear probe but only 10
' compares with double hashing.


' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
' set up hash table
' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LET I.prime.max = 32719                ' large prime for hash table size = M
LET I.prime.nxt = I.prime.max - 2      ' secondary hash increment = M - 2
LET I.hasht.max = I.prime.max          ' max size of hash table
LET I.hasht.min = 0                    ' min size of hash table

DIM I.hash.table( I.hasht.min: I.hasht.max)
				       ' long int hash table, 0 ... 32719

LET L.max.val = ( 2 ^ 22) - 1          ' largest numeric value to hash
				       '    is 8,388,607
LET I.sen.val = 32767                  ' sentinel value > i.hasht.max

FOR I = 0 TO I.hasht.max               ' loop to initialize hash table to
   LET I.hash.table( I) = I.sen.val    '   sentinel value of 32767
NEXT i

LET I.prefix = 0                       ' initialize prefix code to a
				       '    sequence number of zero
LET I.seq.no = -1                      ' initialize sequence number so
				       '    that subsequent increment of
				       '    seq no + 1 (or 0) is the first

' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
' get next input byte to compress
' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LET I.prefix = 8191                    ' sample prefix value is an arbitrary
				       '    sequence number in the LZW table
				       '    and refers to a compressed string
LET I.suffix =  255                    ' next input byte to compress

LET L.search.val = I.prefix * 256 + I.suffix
				       ' this builds a numeric value to hash
				       ' ( = 2,097,151)

' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
' hashsearch
' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LET I.hash01 = L.search.val MOD I.prime.max
				       ' first hash value calculated

LET I.hash02 = I.prime.nxt - ( L.search.val MOD I.prime.nxt)
				       ' second hash value calculated
LET I.hash03  = I.has01                ' third  hash value initialized

WHILE (              I.hash.table( I.hash03)  <> I.sen.val) _
  AND ( I.LZ.prefix( I.hash.table( I.hash03)) <> I.prefix ) _
  AND ( I.LZ.suffix( I.hash.table( I.hash03)) <> I.suffix )
				       ' this loop searches for the next
				       '    available empty hash slot
   LET I.hash03 = ( I.hash03 + I.hash02) MOD I.prime.max
WEND

LET I.hash.result = I.hash.table( I.hash03)

IF I.hash.result <> I.sen.val THEN
   LET I.prefix = I.hash.result        ' result is the sequence no
ELSE
   LET I.seq.no = I.seq.no + 1         ' increment sequence no of the
				       '    next code to be inserted
   LET I.hash.table( I.hash03) = I.seq.no
				       ' insert sequence no of code
				       '   into hash table
   LET I.LZ.prefix( I.seq.no) = I.prefix
				       ' build compression output table
   LET I.LZ.suffix( I.seq.no) = I.suffix
				       ' build compression output table
   LET I.prefix = 0                    ' clear prefix code
END IF


' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
'jump where next byte is input for compression & prefix + suffix catenated
' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

END


