###########################################
#
#  MongoPool
#
#  An MongoDB pooled client for use with threaded
#  applications such as web sites.
#
###########################################

## A simple pure-nim mongodb pooled client designed for use with threaded
## applications such as `Jester <https://github.com/dom96/jester>`__.
## 
## HOW TO USE
## ==========
## 
## 1. Import the library. But, you will also *really* want the `bson <https://github.com/JohnAD/bson>`__
##    library as well since you will be using BSON documents.
##
## .. code:: nim
##
##     import mongopool
##     import bson
##
## 2. Connect to MongoDB using the 'connectMongoPool' procedure.
##
## .. code:: nim
##
##     connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
## 
## 3. Grab a connection from that pool.
##
## .. code:: nim
##
##     var db = getNextConnection()
##
## 4. Use it to do things! See the section called `BASIC CRUD <#basic-crud>`__ for quick examples.
##
## .. code:: nim
##
##     var doc = db.find("mycollection", @@{"name": "jerry"}).returnOne()
##
## 5. Release the connection when done.
##
## .. code:: nim
##
##     releaseConnection(db)
##
## HOW TO USE (THREADED)
## =====================
##
## The whole point of this library is threaded application use. Two key things
## to keep in mind:
##
## 1. You must call ``connectMongoPool`` **before** the threading begins.
##
## 2. Once inside the thread, you must both call ``getNextConnection`` for the 
##    next available connection and call ``releaseConnection`` before finishing
##    the thread.
##
## Failing to call ``releaseConnection`` will keep the connection in-use even
## after the thread closes.
##
## Here is an example that uses Jester to make a web site:
##
## .. code:: nim
##
##     import jester
##     import mongopool
##     import bson
##     
##     connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
##     
##     routes:
##       get "/":
##         #
##         # get a connection:
##         #
##         var db = getNextConnection()
##         #
##         # doing something with it:
##         #
##         var doc = db.find("temp").returnOne()
##         #
##         # releasing it before the thread closes
##         #
##         releaseConnection(db)
##         #
##         resp "doc = " & $doc
##
## BASIC CRUD
## ==========
##
## Some quick examples of how to Create, Read, Update, and Delete and their
## related functions. See the appendix references for more details.
##
## CREATE
## ------
## 
## Example:
##
## .. code:: nim
##
##     import mongopool
##     import bson
##     import strutils
##     connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
##     var db = getNextConnection()
##
##     let joe = @@{
##       "name": "Joe",
##       "age": 42
##     }
##     let personFinal = db.insertOne("people", joe)
##     echo "$1 was given an _id of $2".format(personFinal["name"], personFinal["_id"])
##
##     releaseConnection(db)
##
## related functions: 
## `insertMany <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#insertmany>`__, 
## `insertOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#insertone>`__
##
## READ (FIND)
## -----------
## 
## .. code:: nim
##
##     import mongopool
##     import bson
##     import strutils
##     connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
##     var db = getNextConnection()
##
##     var docs = db.find("people", @@{"age": {"$gt": 21}}).sort(@@{"name": 1}).limit(10).returnMany()
##
##     for doc in docs:
##       echo "name: $1, age $2".format(doc["name"], doc["age"])
##
##     releaseConnection(db)
##
## related functions:
##
## * to start the query: `find <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#find>`__
##
## * to modify the query: 
##   `limit <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#limit>`__,
##   `skip <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#skip>`__,
##   `sort <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#sort>`__
##
## * to get results from the query: 
##   `returnCount <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returncount>`__, 
##   `returnMany <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returnmany>`__, 
##   `returnOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returnone>`__
##
## UPDATE
## ------
## 
## .. code:: nim
##
##     import mongopool
##     import bson
##     connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
##     var db = getNextConnection()
##
##     var joe = db.find("people", @@{"name": "Joe"}).returnOne()
##     joe["age"] = 43
##     let ctr = db.replaceOne("people", @@{"_id": joe["_id"]}, joe)
##     if ctr == 1:
##       echo "change made!"
##
##     releaseConnection(db)
##
## related functions: 
## `replaceOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#replaceone>`__, 
## `updateMany <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#updatemany>`__
##
## DELETE
## ------
## 
## .. code:: nim
##
##     import mongopool
##     import bson
##     import strutils
##     connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
##     var db = getNextConnection()
##
##     var ctr = db.deleteMany("people", @@{"name": "Larry"})
##     echo "$1 people named Larry removed.".format(ctr)
##
##     releaseConnection(db)
##
## related functions: 
## `deleteMany <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#deletemany>`__, 
## `deleteOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#deleteone>`__
##
## Credit
## ======
##
## Large portions of this code were pulled from the nimongo project, a scalable
## pure-nim MongoDb driver. See https://github.com/SSPkrolik/nimongo
##
## If you are doing batch processing or internally-asynchronous manipulation of
## MongoDb, I recommend using using nimongo rather than this library. nimongo can
## be a very powerful tool.
##
## On the other hand, if you are using MongoDB from an application that is
## already doing it's own asynchronous threading and you need a driver that does
## NOT thread, but is instead friendly to already-existing threads with pooling,
## then this might be the better library.

# Required for using _Lock on linux
when hostOs == "linux":
    {.passL: "-pthread".}

# import asyncdispatch
# import asyncnet
import net
import base64
import locks
import random
import md5
import net
import oids
import sequtils
import streams
import strutils
import tables
import typetraits
import times
import uri
import os
import deques
import re

import bson except `()`

import scram/client

import mongopool/errors
import mongopool/proto
import mongopool/reply
import mongopool/writeconcern

randomize()

export errors

type
  MongoConnection* = object
    active: bool
    id: int
    asocket: Socket
    requestId: int32
    currentDatabase: string
    writeConcern: WriteConcern
    msg: string
  FindQuery = object     ## MongoDB cursor: manages queries object lazily
    connection: MongoConnection
    requestId: int32
    databaseName: string
    collectionName: string
    query: Bson
    fields: seq[string]
    # queryFlags: int32
    nskip: int32
    nlimit: int32
    sorting: Bson
    writeConcern: WriteConcern

#
# Global variables
#

# var masterPool = MongoPool()

var
  masterPool_originalUrl: string
  masterPool_hostname: string
  masterPool_port: uint16
  masterPool_username: string
  masterPool_password: string
  masterPool_database: string
  masterPool_options: Table[string, string]
  masterPool_authMechanism: string
  masterPool_useSSL: bool
  masterPool_authDatabase: string
  masterPool_lastErrMsg: string
  #
  masterPool_asockets: Table[int, Socket]
  masterPool_connStatus: Table[int, string]
  masterPool_lastUsed: Table[int, int64] # Unix time integer (seconds since Jan 1, 1970)
  masterPool_working = initDeque[int]()
  masterPool_available = initDeque[int]()
  masterPool_minConnections: int
  masterPool_maxConnections: int
  masterPool_writeConcern: WriteConcern

const
  AUTHMECH_SHA1 = "SCRAM-SHA-1"
  AUTHMECH_SHA256 = "SCRAM-SHA-256"
  AUTHMECH_CR = "MONGODB-CR"
  AUTHMECH_NONE = "NONE"


when compileOption("threads"):
  var dbThread {.threadvar.}: MongoConnection
  let masterThreadId = getThreadId()

#
# supporting procedures
#

proc obscure(url: string): string =
  var matches: array[3, string]
  if match(url, re"([^/]+//[^:]*:)([^@]+)(@.*)", matches):
    result = matches[0] & "<password>" & matches[2]
  else:
    result = "$1".format(url)


proc currentTime(): int64 =
  result = getTime().toUnix


proc nextRequestId(mc: var MongoConnection): int32 =
    # Return next request id for current MongoDB client
    mc.requestId = (mc.requestId + 1) mod (int32.high - 1'i32)
    return mc.requestId


proc makeQuery(c: var MongoConnection, collection: string, query: Bson, fields: seq[string] = @[]): FindQuery =
  # Create lazy query object to MongoDB that can be actually run
  # by one of the Find object procedures: `returnOne()` or `returnMany()`.
  result = FindQuery()
  result.connection = c
  result.requestId = c.nextRequestId
  result.collectionName = collection
  result.databaseName = c.currentDatabase
  result.query = query
  result.fields = fields
  result.nskip = 0
  result.nlimit = 0
  result.writeConcern = c.writeConcern


#
# primary procedures
#


proc sort*(f: FindQuery, order: Bson): FindQuery =
  ## Add sorting criteria to a query.
  ##
  ## this function DOES NOT affect the data on the database; merely the order
  ## in which found documents are presented from the query.
  ##
  ## order
  ##   See https://docs.mongodb.com/manual/reference/method/cursor.sort/index.html
  ##
  ## Returns a new ``FindQuery`` copy
  result = f
  result.query["$orderby"] = order


proc skip*(f: FindQuery, numSkip: int32): FindQuery =
  ## For a query returning multiple documents, this specifies
  ## how many should be skipped first.
  ##
  ## Returns a new ``FindQuery`` copy.
  result = f
  result.nskip = numSkip


proc limit*(f: FindQuery, numLimit: int32): FindQuery =
  ## Limits the number of documents the query will return
  ##
  ## Returns a new query copy
  result = f
  result.nlimit = numLimit


proc find*(db: var MongoConnection, collection: string, criteria: Bson = @@{}, fields: seq[string] = @[]): FindQuery =
  ## Starts a query to find documents in the database.
  ## 
  ## collection
  ##   The collection to search
  ## criteria
  ##   specifies the search conditions
  ## fields 
  ##   limits which top-level fields are returned in each document found
  ##
  ## Returns a passive 'FindQuery' object. Nothing useful is returned until
  ## that object is applied to a "return" routine, such as ``returnOne``, 
  ## ``returnMany``, or ``returnCount``.
  let filter = @@ {
    "$query": criteria
  }
  result = makeQuery(db, collection, filter, fields)


proc prepareQuery(f: FindQuery, requestId: int32, numberToReturn: int32, numberToSkip: int32): string =
  # Prepare query and request queries for making OP_QUERY
  var bfields: Bson = newBsonDocument()
  if f.fields.len() > 0:
      for field in f.fields.items():
          bfields[field] = 1'i32.toBson()
  let squery = f.query.bytes()
  let sfields: string = if f.fields.len() > 0: bfields.bytes() else: ""

  result = ""
  let colName = "$1.$2".format(f.databaseName, f.collectionName)
  buildMessageHeader(int32(29 + colName.len + squery.len + sfields.len),
    requestId, 0, result)

  buildMessageQuery(0, colName, numberToSkip , numberToReturn, result)
  result &= squery
  result &= sfields


proc handleResponses(db: FindQuery, target: var seq[Bson]) =
  var data: string = db.connection.asocket.recv(4)
  if data == "":
    raise newException(CommunicationError, "Disconnected from MongoDB server")

  var stream: Stream = newStringStream(data)
  let messageLength: int32 = stream.readInt32() - 4

  ## Read data
  data = ""
  while data.len < messageLength:
    let chunk: string = db.connection.asocket.recv(messageLength - data.len)
    if chunk == "":
      raise newException(CommunicationError, "Disconnected from MongoDB server")
    data &= chunk

  stream = newStringStream(data)

  discard stream.readInt32()                     ## requestID
  let responseTo = stream.readInt32()            ## responseTo
  discard stream.readInt32()                     ## opCode
  discard stream.readInt32()                     ## responseFlags
  discard stream.readInt64()                     ## cursorID
  discard stream.readInt32()                     ## startingFrom
  let numberReturned: int32 = stream.readInt32() ## numberReturned

  var res: seq[Bson] = @[]

  if numberReturned > 0:
    for i in 0..<numberReturned:
      res.add(newBsonDocument(stream))
  
  target = res


iterator performFind(f: FindQuery, 
                     numberToReturn: int32, 
                     numberToSkip: int32): Bson {.closure.} =
  ## Private procedure for performing actual query to Mongo
  if f.connection.asocket.trySend(prepareQuery(f, f.requestId, numberToReturn, numberToSkip)):
    var data: string = newStringOfCap(4)
    var received: int = f.connection.asocket.recv(data, 4)
    var stream: Stream = newStringStream(data)
    {.gcsafe.}:
      masterPool_lastUsed[f.connection.id] = currentTime()

    ## Read data
    let messageLength: int32 = stream.readInt32()

    data = newStringOfCap(messageLength - 4)
    received = f.connection.asocket.recv(data, messageLength - 4)
    stream = newStringStream(data)

    discard stream.readInt32()                     ## requestId
    discard stream.readInt32()                     ## responseTo
    discard stream.readInt32()                     ## opCode
    discard stream.readInt32()                     ## responseFlags
    discard stream.readInt64()                     ## cursorID
    discard stream.readInt32()                     ## startingFrom
    let numberReturned: int32 = stream.readInt32() ## numberReturned

    if numberReturned > 0:
      for i in 0..<numberReturned:
        yield newBsonDocument(stream)
    elif numberToReturn == 1:
      raise newException(NotFound, "No documents matching query were found")
    else:
      discard


proc returnMany*(f: FindQuery): seq[Bson] =
  ## Executes the query and returns the matching documents.
  ##
  ## Returns a sequence of BSON documents.
  for doc in f.performFind(f.nlimit, f.nskip):
    result.add(doc)


proc returnOne*(f: FindQuery): Bson =
  ## Executes the query and returns the first document.
  ##
  ## If `skip` has been added to the query it will honor that and skip
  ## ahead before finding the first.
  ## 
  ## Returns a single BSON document. If nothing is found,
  ## it generates a ``NotFound`` error.
  var temp: seq[Bson]
  for doc in f.performFind(1, 0):
    temp.add(doc)
  if temp.len == 0:
    raise newException(NotFound, "No documents matching query were found")
  result = temp[0]


proc returnCount*(f: FindQuery): int =
  ## Executes the query and returns the count of documents found
  ## (rather than the documents themselves).
  ##
  ## If no documents are found, 0 is returned.
  var count: FindQuery = f
  count.query["count"] = toBson(f.collectionName)
  count.query["query"] = f.query["$query"]
  count.query.del("$query")
  count.collectionName = "$cmd"
  var docs: seq[Bson]
  for doc in count.performFind(f.nlimit, f.nskip):
    docs.add(doc)
  handleStatusReply(docs[0])
  # echo "--"
  # echo count.query
  # echo docs[0]
  return docs[0].getReplyN


proc drop*(db: var MongoConnection, collection: string, writeConcern: Bson = null()): bool =
  ## Drops (removes) a collection from the current database.
  ##
  ## This also deletes all documents found in that collection. Use with caution.
  ##
  ## To create a collection, simply use it. Any inserted document will create the
  ## collection if it does not already exist.
  ##
  ## collection
  ##   the collection to be dropped
  ##
  ## Returns true if the collection was successfully dropped. Otherwise returns false.
  result = false
  let request = @@{
    "drop": collection,
    "writeConcern": if writeConcern.isNull: db.writeConcern else: writeConcern
  }
  var query = makeQuery(db, "$cmd", request)
  var response = query.returnOne()
  let tsr = toStatusReply(response)
  result = tsr.ok


proc insertMany*(db: var MongoConnection, collection: string, documents: seq[Bson], ordered: bool = true, writeConcern: Bson = null()): seq[Bson] =
  ## Insert new documents into MongoDB.
  ##
  ## If problems prevent the insertion, an error is generated.
  ##
  ## collection
  ##   the collection to receive the new document(s)
  ## documents
  ##   a sequence of BSON documents to be inserted
  ## ordered
  ##   if true, the database should insert them one-after-the-next
  ## writeConcern
  ##   TBD
  ##
  ## Returns the newly inserted documents, including any ``_id`` fields auto-created.

  # 
  # insert any missing _id fields
  #
  var id = ""
  var final_docs: seq[Bson] = @[]
  for doc in documents:
    when defined(nimV2):
      var freshCopy = doc
    else:
      var freshCopy = doc.deepCopy
    if not freshCopy.contains("_id"):
      freshCopy["_id"] = toBson(genOid())
    final_docs.add freshCopy
  #
  # build & send Mongo query
  #
  let request = @@{
    "insert": collection,
    "documents": final_docs,
    "ordered": ordered,
    "writeConcern": if writeConcern.isNull: db.writeConcern else: writeConcern
  }
  var query = makeQuery(db, "$cmd", request)
  var response = query.returnOne()
  handleStatusReply(response)
  result = final_docs


proc insertOne*(db: var MongoConnection, collection: string, document: Bson, ordered: bool = true, writeConcern: Bson = null()): Bson =
  ## Insert one new document into MongoDB
  ##
  ## Returns the newly inserted document, including an _id field if auto-created.
  ##
  ## collection
  ##   the collection to receive the new document(s)
  ## document
  ##   the BSON documents to be inserted
  ##
  ## If problems prevent the insertion, an error is generated.
  var temp = db.insertMany(collection, @[document], ordered, writeConcern)
  return temp[0]


proc updateMany*(db: var MongoConnection, collection: string, filter: Bson, update: Bson): int =
  ## Update multiple MongoDB documents.
  ##
  ## See
  ## https://docs.mongodb.com/manual/reference/method/db.collection.updateMany/
  ## for more details.
  ##
  ## collection
  ##   the name of the collection to update
  ## filter
  ##   a query limiting which documents should be updated
  ## update
  ##   a BSON description of what changes to make.
  ##
  ## Returns the count of documents given the update.
  ##
  ## Note: if a document already had the new values, it is still included
  ## in the final count.
  let request = @@ {
    "update": collection,
    "updates": [@@{"q": filter, "u": update, "upsert": false, "multi": true}],
    "ordered": true
  }
  let response = makeQuery(db, "$cmd", request).returnOne()
  handleStatusReply(response)
  handleWriteErrors(response)
  result = response.getReplyN


proc replaceOne*(db: var MongoConnection, collection: string, filter: Bson, replacement: Bson, upsert = false): int =
  ## Replace one MongoDB document.
  ##
  ## See
  ## https://docs.mongodb.com/manual/reference/method/db.collection.replaceOne/
  ## for more details.
  ##
  ## collection 
  ##   the name of the collection to update
  ## filter
  ##   a query locating which document to be updated
  ## replacement
  ##   the new BSON document.
  ## upsert 
  ##   should be true if an insert should occur if the document is not found; otherwise set to false.
  ##
  ## You can leave the ``_id`` field out of the replacement document and the
  ## replacement will have the previous doc's ``_id``.
  ##
  ## Returns a 1 if document was found matching the filter; otherwise 0.
  ##
  ## Note: it returns a 1 on a match even if the document already had the changes.
  let request = @@ {
    "update": collection,
    "updates": [@@{"q": filter, "u": replacement, "upsert": upsert, "multi": false}],
    "ordered": true
  }
  let response = makeQuery(db, "$cmd", request).returnOne()
  handleStatusReply(response)
  handleWriteErrors(response)
  result = response.getReplyN

proc deleteMany*(db: var MongoConnection, collection: string, filter: Bson, limit: int = 0, writeConcern: Bson = null()): int =
  ## Deletes multiple MongoDB documents.
  ##
  ## See:
  ## https://docs.mongodb.com/manual/reference/method/db.collection.deleteMany
  ## for more details.
  ##
  ## collection 
  ##   the name of hte collection to update
  ## filter 
  ##   a BSON query limiting which documents should be deleted
  ## limit 
  ##   restricts the number documents deleted. 0 means no limit.
  ## writeConcern
  ##   TBD
  ##
  ## Returns the number of documents deleted.
  let
    request = @@{
      "delete": collection,
      "deletes": [@@{"q": filter, "limit": limit}],
      "writeConcern": if writeConcern.isNull: db.writeConcern else: writeConcern
    }
    response = makeQuery(db, "$cmd", request).returnOne()
  handleStatusReply(response)
  return response.getReplyN


proc deleteOne*(db: var MongoConnection, collection: string, filter: Bson, writeConcern: Bson = null()): int =
  ## Deletes one MongoDB document.
  ##
  ## See:
  ## https://docs.mongodb.com/manual/reference/method/db.collection.deleteOne
  ## for more details.
  ##
  ## collection
  ##   the name of the collection to update
  ## filter
  ##   a BSON query to locate which document should be deleted
  ## writeConcern 
  ##   TBD
  ##
  ## This procedure is very similar to ``deleteMany`` except that failure to
  ## locate the document will raise a ``NotFound`` error. To avoid the
  ## ``NotFound`` error, simply use ``deleteMany`` with a ``limit`` set to 1.
  ##
  ## Returns the number of documents deleted, which will be 1.
  let count = deleteMany(db, collection, filter, limit=1, writeConcern=writeConcern)
  if count == 0:
    raise newException(NotFound, "Unable to locate document to be deleted.")
  return count


proc getDatabase*(db: var MongoConnection): string =
  ## Get the current database name associated with this connection.
  ## This starts out as the database referenced in the connection URL,
  ## but can be changed with the changeDatabase procedure.
  ##
  ## Returns the name of the current database.
  result = db.currentDatabase


proc changeDatabase*(db: var MongoConnection, database: string) =
  ## Change the current connection to use a different database than the
  ## one specified in the connection URL. This is rarely approved
  ## behaviour for non-admin accounts.
  ## Once changed, all future queries on this connection will be in
  ## reference to this database (until the thread closes).
  ##
  ## See ``getDatabase`` to get the current database name
  db.currentDatabase = database

# proc authMongodbCR*(db: Database[Mongo], username: string, password: string): bool {.discardable.} =
#   ## Authenticate connection (sync): using MONGODB-CR auth method
#   if username == "" or password == "":
#     return false

#   let nonce: string = db["$cmd"].makeQuery(@@{"getnonce": 1'i32}).one()["nonce"]
#   let passwordDigest = $toMd5("$#:mongo:$#" % [username, password])
#   let key = $toMd5("$#$#$#" % [nonce, username, passwordDigest])
#   let request = @@{
#     "authenticate": 1'i32,
#     "mechanism": "MONGODB-CR",
#     "user": username,
#     "nonce": nonce,
#     "key": key,
#     "autoAuthorize": 1'i32
#   }
#   let response = db["$cmd"].makeQuery(request).one()
#   return response.isReplyOk

proc decodeQuery(u: Uri): Table[string, string] =
  result = initTable[string, string]()
  let items = u.query.split("&")
  for item in items:
    let parts = item.split("=")
    if len(parts) == 2:
      result[parts[0]] = parts[1]


proc authScramSha1(db: var MongoConnection): bool =
  ## Authenticate connection (async) using the SCRAM-SHA-1 method

  var scramClient = newScramClient[SHA1Digest]()
  let clientFirstMessage = scramClient.prepareFirstMessage(masterPool_username)

  #
  # request START
  #
  let requestStart = @@{
    "saslStart": 1'i32,
    "mechanism": AUTHMECH_SHA1,
    "payload": bin(clientFirstMessage),
    "autoAuthorize": 1'i32
  }
  var query = db.makeQuery("$cmd", requestStart)
  var responseStart: Bson
  try:
    responseStart = query.returnOne()
  except:
    return false
  if responseStart.contains("code"):
    return false #connect failed or auth failure
  #
  # send MD5'd credentials
  #
  let
    responsePayload = binstr(responseStart["payload"])
    passwordDigest = $toMd5("$#:mongo:$#" % [masterPool_username, masterPool_password])
    clientFinalMessage = scramClient.prepareFinalMessage(passwordDigest, responsePayload)

  let requestContinue1 = @@{
    "saslContinue": 1'i32,
    "conversationId": toInt32(responseStart["conversationId"]),
    "payload": bin(clientFinalMessage)
  }
  query = db.makeQuery("$cmd", requestContinue1)
  let responseContinue1 = query.returnOne()
  if responseContinue1["ok"].toFloat64() == 0.0:
    return false
  if not scramClient.verifyServerFinalMessage(binstr(responseContinue1["payload"])):
    raise newException(Exception, "Server returned an invalid signature.")


proc authScramSha256(db: var MongoConnection): bool =
  ## Authenticate connection (async) using the SCRAM-SHA-256 method

  var scramClient = newScramClient[SHA256Digest]()
  let clientFirstMessage = scramClient.prepareFirstMessage(masterPool_username)

  #
  # request START
  #
  let requestStart = @@{
    "saslStart": 1'i32,
    "mechanism": AUTHMECH_SHA256,
    "payload": bin(clientFirstMessage),
    "autoAuthorize": 1'i32
  }
  var query = db.makeQuery("$cmd", requestStart)
  var responseStart: Bson
  try:
    responseStart = query.returnOne()
  except:
    return false
  if responseStart.contains("code"):
    return false #connect failed or auth failure
  #
  # send MD5'd credentials
  #
  let
    responsePayload = binstr(responseStart["payload"])
    passwordDigest = $toMd5("$#:mongo:$#" % [masterPool_username, masterPool_password])
    clientFinalMessage = scramClient.prepareFinalMessage(passwordDigest, responsePayload)

  let requestContinue1 = @@{
    "saslContinue": 1'i32,
    "conversationId": toInt32(responseStart["conversationId"]),
    "payload": bin(clientFinalMessage)
  }
  query = db.makeQuery("$cmd", requestContinue1)
  let responseContinue1 = query.returnOne()
  if responseContinue1["ok"].toFloat64() == 0.0:
    return false
  if not scramClient.verifyServerFinalMessage(binstr(responseContinue1["payload"])):
    raise newException(Exception, "Server returned an invalid signature.")
  #
  # send optional closing FINAL message
  #

  # Depending on how it's configured, Cyrus SASL (which the server uses)
  # requires a third empty challenge.
  if not responseContinue1["done"].toBool():
    let requestContinue2 = @@{
      "saslContinue": 1'i32,
      "conversationId": responseContinue1["conversationId"],
      "payload": ""
    }
    query = db.makeQuery("$cmd", requestContinue2)
    let responseContinue2 = query.returnOne()
    if not responseContinue2["done"].toBool():
      raise newException(Exception, "SASL conversation failed to complete.")
  return true


proc addConnection() {.gcsafe.} = 
  {.gcsafe.}:
    #
    # get next largest number
    #
    var largest_so_far = 0
    for i in masterPool_asockets.keys:
      if i > largest_so_far:
        largest_so_far = i
    let next = largest_so_far + 1
    #
    # add one more entry
    #
    when defined(ssl):
      var ctx = newContext()
    var next_socket = newSocket()
    var next_status = "pending TCP connect"
    if masterPool_useSSL:
      next_status = "pending SSL connect"
      when defined(ssl):
        wrapSocket(ctx, next_socket)
      else:
        raise newException(CommunicationError, "MongoDB URI specifies SSL via 'ssl=true', but not compiled with -d:ssl flag")
    #
    # establish a connection to the server
    #
    try:
      next_socket.connect(masterPool_hostname, Port(masterPool_port), 1000)
      next_status = "TCP/IP connected"
      # echo "TCP connect $1".format(next)
    except OSError:
      masterPool_lastErrMsg = "warning: mongopool failed TCP connect $1".format(next)
      sleep(400)
      return
    except TimeoutError:
      masterPool_lastErrMsg = "warning: mongopool timeout on connect $1".format(next)
      sleep(400)
      return
    #
    # now authenticate the connection
    #
    try:
      var authResult = false
      case masterPool_authMechanism:
      of AUTHMECH_SHA1:
        var tempConn = MongoConnection()
        tempConn.active = true
        tempConn.id = next
        tempConn.asocket = next_socket
        tempConn.currentDatabase = masterPool_authDatabase
        authResult = authScramSha1(tempConn)
        if authResult:
          next_status = "Authenticated socket ready."
      of AUTHMECH_SHA256:
        var tempConn = MongoConnection()
        tempConn.active = true
        tempConn.id = next
        tempConn.asocket = next_socket
        tempConn.currentDatabase = masterPool_authDatabase
        authResult = authScramSha256(tempConn)
        if authResult:
          next_status = "Authenticated socket ready."
      of AUTHMECH_CR:
        authResult = true
        next_status = "[UNSUPPORTED] Unauthenticated socket ready."
      else:
        authResult = true
        next_status = "Unauthenticated socket ready."
      if authResult:
        masterPool_asockets[next] = next_socket
        masterPool_connStatus[next] = next_status
        masterPool_lastUsed[next] = currentTime()
        masterPool_working.addLast next
        masterPool_available.addLast(next) # because of threading, this must happen LAST
      else:
        masterPool_lastErrMsg = "warning: failed AUTHRESULT ($1) on attempted connection $2".format(masterPool_authMechanism, next)
    except:       
      masterPool_lastErrMsg = "warning: failed AUTH on attempted connection $1 ($2)".format(next, getCurrentExceptionMsg())
      sleep(200)
      return


proc getMongoPoolStatus*(): string {.gcsafe.} =
  ## Returns a string showing the database pool's current state.
  ##
  ## An attempt is made to cover any password in the url.
  ##
  ## It appears in the form of:
  ##
  ## .. code::
  ##
  ##     mongopool (default):
  ##       url: mongodb://user:<password>@mongodb.servers.somedomain.com:27017/blahblah
  ##       auth:
  ##         mechanism: SCRAM-SHA-1
  ##         database: blahblah
  ##       database: blahblah
  ##       most recent error: blahblah
  ##       min max: 4 20
  ##       sockets:
  ##         pool size: 4
  ##         working: 4
  ##         available: 4
  ##         available pool indexes: [1, 2, 3, 4]
  ##         last used: 1
  ##         [1] =   (avail) "Authenticated socket ready." idle: 12s
  ##         [2] =   (avail) "Authenticated socket ready." idle: 2322s
  ##         [3] =   (avail) "Authenticated socket ready." idle: 1s
  ##         [4] =   (avail) "Authenticated socket ready." idle: 94s
  ##
  {.gcsafe.}:
    let redactedUrl = masterPool_originalUrl.obscure
    result = "mongopool (default):\n"
    result &= "  url: $1\n".format(redactedUrl)
    result &= "  auth:\n"
    result &= "    mechanism: $1\n".format(masterPool_authMechanism)
    result &= "    database: $1\n".format(masterPool_authDatabase)
    result &= "  database: $1\n".format(masterPool_database)
    result &= "  most recent error: $1\n".format(masterPool_lastErrMsg)
    result &= "  min max: $1 $2\n".format(masterPool_minConnections, masterPool_maxConnections)
    result &= "  sockets:\n"
    result &= "    pool size: $1\n".format(masterPool_asockets.len)
    result &= "    working: $1\n".format(masterPool_working.len)
    result &= "    available: $1\n".format(masterPool_available.len)
    result &= "    available pool indexes: $1\n".format($masterPool_available)
    if len(masterPool_available) == 0:
      result &= "    last used: detail not available\n"
    else:
      result &= "    last used: $1\n".format(masterPool_available.peekLast)
    let rightNow = currentTime()
    for index, stat in masterPool_connStatus.pairs:
      var activeStat = "   (dead)"
      let idleTime = rightNow - masterPool_lastUsed[index]
      if index in masterPool_working:
        activeStat = "(working)"
      if index in masterPool_available:
        activeStat = "  (avail)"
      result &= "    [$1] = $2 \"$3\" idle: $4s\n".format(index, activeStat, stat, idleTime)


proc connectMongoPool*(url: string, minConnections = 4, maxConnections = 20, loose=false) {.gcsafe.} =
  ## This procedure connects to the MongoDB database using the supplied
  ## `url` string. That URL should be in the form of:
  ## 
  ## .. code::
  ##
  ##     mongodb://[username:password@]host1[:port1][,...hostN[:portN]][/[database][?options]]
  ##
  ## It is recommended that you include the `database` name in the URL.
  ## Otherwise, it will default to "admin", which is probably not right.
  ## If the ``username`` is not present, then the connection is assumed to not
  ## support authentication. If an ``authMechanism`` option is not present, but
  ## a ``username`` is supplied, then the authenication is assumed to be SCRAM-SHA-1.
  ## If the ``authSource`` option is not present, the database used just for
  ## authentication is assumed to be the main ``database`` name.
  ##
  ## url
  ##   url of the MongoDB server to connect to
  ## minConnections 
  ##   determines the number of database connections to start with
  ## maxConnections
  ##   determines the maximum allowed *active* connections
  ## loose
  ##   if ``true`` then the connection need not be successful.
  ##
  ## Behind the scenes, a set of global variables prefixed with ``masterPool_``
  ## are set. Those variables are private to the library.
  ##
  ## If the compiler is called with ``--threads:on`` this procedure will verify that
  ## it is not in a running thread. If it is within a running thread, it raises
  ## an ``OSError`` at run-time.
  #
  # parse the URL
  #
  when compileOption("threads"):
    if masterThreadId != getThreadId():
      raise newException(OSError, "You cannot call connectMongoPool from within a thread.")
  {.gcsafe.}:
    var uDetail = parseUri(url)
    masterPool_originalUrl = url
    masterPool_hostname = uDetail.hostname
    masterPool_port = if uDetail.port.len > 0: parseInt(uDetail.port).uint16 else: 27017'u16
    masterPool_username = uDetail.username
    masterPool_password = uDetail.password
    masterPool_database = uDetail.path.extractFileName()
    masterPool_options = decodeQuery(uDetail)
    #
    # assign auth method details
    #
    if masterPool_username == "":
      masterPool_authMechanism = AUTHMECH_NONE
    else:
      if "authMechanism" in masterPool_options:
        let mech = masterPool_options["authMechanism"]
        case mech:
        of AUTHMECH_SHA256:
          masterPool_authMechanism = mech
        of AUTHMECH_SHA1:
          masterPool_authMechanism = mech
        of AUTHMECH_CR:
          masterPool_authMechanism = mech
        else:
          raise newException(CommunicationError, 
                             "MongoPool library does not currently support the " &
                             "$1 authentication mechanism.".format(mech))
      else:
        masterPool_authMechanism = AUTHMECH_SHA1
      if "authSource" in masterPool_options:
        masterPool_authDatabase = masterPool_options["authSource"]
      else:
        masterPool_authDatabase = masterPool_database
    if masterPool_authDatabase == "":
      masterPool_authDatabase = "admin"
    if "ssl" in masterPool_options:
      if masterPool_options["ssl"].toLower() == "true":
        masterPool_useSSL = true
      else:
        masterPool_useSSL = false
    masterPool_writeConcern = writeConcernDefault()
    #
    # establish the minimum connections
    #
    masterPool_minConnections = minConnections
    masterPool_maxConnections = maxConnections
    masterPool_asockets = initTable[int, Socket]()
    masterPool_connStatus = initTable[int, string]()
    masterPool_lastUsed = initTable[int, int64]()
    masterPool_available = initDeque[int]()
    for i in 1..minConnections:
      addConnection()
    #
    # check everything
    #
    if masterPool_available.len == 0:
      if not loose:
        echo getMongoPoolStatus()
        raise newException(CommunicationError, "Unable to make ANY connections to MongoDB")
    when compileOption("threads"):
      if masterThreadId == getThreadId():
        echo "mongopool ready for threaded use"


proc getLastErrorMessage*(): string {.gcsafe.} =
  ## Get the last error message seen by any database connection.
  {.gcsafe.}:
    result = "$1".format(masterPool_lastErrMsg)


proc setLastErrorMessage*(msg: string) {.gcsafe.} =
  ## Allows the application artificially to set the "last error message" seen
  ## by the pool of database connections.  
  {.gcsafe.}:
    masterPool_lastErrMsg = msg


proc getNextFromSpecific(): MongoConnection {.gcsafe.} =
  {.gcsafe.}:
    result = MongoConnection()
    result.active = false
    while masterPool_available.len == 0:
      if masterPool_asockets.len >= masterPool_maxConnections:
        masterPool_lastErrMsg = "Out of capacity -- reached max connections ($1)".format(masterPool_maxConnections)
        raise newException(MongoPoolCapacityReached, "Out of capacity -- reached max connections ($1)".format(masterPool_maxConnections))
      addConnection()
    if masterPool_available.len == 0:
      # masterPool_lastErrMsg should have been set by addConnection above
      raise newException(CommunicationError, "No available connections and unable to add to pool.")
    let index = masterPool_available.popFirst
    if index == 0:
      masterPool_lastErrMsg = "getNextFromSpecfic() -- internal error: received a pool index of 0."
      raise newException(CommunicationError, "Internal error: received a pool index of 0.")
    result.id = index
    result.asocket = masterPool_asockets[index]
    result.currentDatabase = masterPool_database
    result.writeConcern = masterPool_writeConcern
    result.active = true
  

proc getNextConnection*(): MongoConnection {.gcsafe.} =
  ## Get a connection from the MongoDB pool.
  ##
  ## If the number of available connections runs out, a new connection
  ## is made. However, if the number of connections has
  ## reached the ``maxConnections`` parameter from ``connectMongoPool``,
  ## then the ``MongoPoolCapacityReached`` error is raised instead.
  ##
  ## When a thread has spawned, the code in the thread can safely get
  ## one of the pre-authenticated established connections from the pool.
  ## 
  ## You will want to call ``releaseConnection`` with the connection
  ## before your thread terminates. Otherwise, the connection will never be
  ## release.
  ##
  ## If you are in the context of a tread, a special threadvar called 
  ## ``dbThread`` is "instanced" for your thread using the thread's own memory
  ## management context. Otherwise, a new instance is called.
  ##
  ## Returns a single connection to the database.
  
  when compileOption("threads"):
    if masterThreadId == getThreadId():
      # non-threaded response:
      result = getNextFromSpecific()
    else:
      # threaded response:
      {.gcsafe.}:
        let temp = getNextFromSpecific()
        dbThread = MongoConnection()
        dbThread.active = false
        when defined(nimV2):
          dbThread.id = temp.id
        else:
          dbThread.id = temp.id.deepCopy
        dbThread.asocket = masterPool_asockets[temp.id]
        when defined(nimV2):
          dbThread.currentDatabase = masterPool_database
          dbThread.writeConcern = masterPool_writeConcern
        else:
          dbThread.currentDatabase = masterPool_database.deepCopy
          dbThread.writeConcern = masterPool_writeConcern.deepCopy
        dbThread.active = true
        return dbThread
  else:
    # non-threaded response:
    result = getNextFromSpecific()


proc releaseConnection*(mc: MongoConnection) {.gcsafe.} =
  ## Release a live database connection back to the MongoDB pool.
  ##
  ## This is safe to call from both a threaded and non-threaded context.
  ## If the passed connection is not active, no action is taken.
  {.gcsafe.}:
    if not mc.active:
      return
    if masterPool_asockets.hasKey(mc.id):
      if not masterPool_available.contains(mc.id):
        masterPool_available.addLast(mc.id)
      else:
        masterPool_lastErrMsg = "in releaseConnection() -- an attempt was made to release already-released index $1.".format(mc.id)
    else:
      masterPool_lastErrMsg = "in releaseConnection() -- an attempt was made to release nonexistent index $1.".format(mc.id)
