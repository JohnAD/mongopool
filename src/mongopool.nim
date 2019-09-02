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
## HOW TO USE (UNTHREADED)
## =======================
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
## The whole point of this library is threaded application use. The biggest
## change is that the connection is pulled using ``getNextConnectionAsThread``
## instead of ``getNextConnection``. Of course, that will only work from inside
## the thread. Here is an example that uses Jester to make a web site:
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
##         var db = getNextConnectionAsThread()
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
## ======
## 
## Example:
##
## .. code:: nim
##
##     import mongopool
##     import bson
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
## `insertMany<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#insertMany.p>`__, 
## `insertOne<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#insertOne.p>`__
##
## READ (FIND)
## -----------
## 
## .. code:: nim
##
##     import mongopool
##     import bson
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
## * to start the query: `find<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#find.p>`__
## * to modify the query: 
##   `limit<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#limit.p>`__,
##   `skip<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#skip.p>`__,
##   `sort<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#sort.p>`__
## * to get results from the query: 
##   `returnCount<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returnCount.p>`__, 
##   `returnMany<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returnMany.p>`__, 
##   `returnOne<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returnOne.p>`__
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
##     let ctr = db.replaceOne(@@{"_id": joe["_id"]}, joe)
##     if ctr == 1:
##       echo "change made!"
##
##     releaseConnection(db)
##
## related functions: 
## `replaceOne<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#replaceOne.p>`__, 
## `deleteOne<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#deleteOne.p>`__
##
## DELETE
## ------
## 
## .. code:: nim
##
##     import mongopool
##     import bson
##     connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
##     var db = getNextConnection()
##
##     var ctr = db.deleteMany("people", @@{"name": "Larry"})
##     echo "$1 people named Larry removed.".format(ctr)
##
##     releaseConnection(db)
##
## related functions: 
## `deleteMany<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#deleteMany.p>`__, 
## `deleteOne<https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#deleteOne.p>`__


# Required for using _Lock on linux
when hostOs == "linux":
    {.passL: "-pthread".}

import asyncdispatch
import asyncnet
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

import bson except `()`

import scram/client

import mongopool/errors
import mongopool/proto
import mongopool/reply
import mongopool/writeconcern

randomize()

export errors

type
  MongoConnection = object
    id: int
    asocket: AsyncSocket
    requestId: int32
    currentDatabase: string
    writeConcern: WriteConcern
  MongoPool = object
    originalUrl: string
    hostname: string
    port: uint16
    username: string
    password: string
    database: string
    options: Table[string, string]
    authMechanism: string
    authDatabase: string
    asockets: Table[int, AsyncSocket]
    connStatus: Table[int, string]
    working: seq[int]
    available: Deque[int]
    minConnections: int
    maxConnections: int
    writeConcern: WriteConcern
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

var masterPool = MongoPool()

var dbThread {.threadvar.}: MongoConnection

#
# supporting procedures
#

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


proc handleResponses(db: FindQuery, target: Future[seq[Bson]]): Future[void] {.async.} =
  var data: string = await db.connection.asocket.recv(4)
  if data == "":
    raise newException(CommunicationError, "Disconnected from MongoDB server")

  var stream: Stream = newStringStream(data)
  let messageLength: int32 = stream.readInt32() - 4

  ## Read data
  data = ""
  while data.len < messageLength:
    let chunk: string = await db.connection.asocket.recv(messageLength - data.len)
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
  
  target.complete(res)



proc performFindAsync(f: FindQuery,
                      numberToReturn: int32,
                      numberToSkip: int32): Future[seq[Bson]] {.async.} =
  # Perform asynchronous OP_QUERY operation to MongoDB.
  #
  await f.connection.asocket.send(prepareQuery(f, f.requestId, numberToReturn, numberToSkip))
  let response = newFuture[seq[Bson]]("recv")
  # ls.queue[requestId] = response
  # if ls.queue.len == 1:
  #   asyncCheck handleResponses(ls)
  var ret = response
  asyncCheck handleResponses(f, ret)
  result = await response


proc returnMany*(f: FindQuery): seq[Bson] =
  ## Executes the query and returns the matching documents.
  ##
  ## Returns a sequence of BSON documents.
  result = waitFor f.performFindAsync(f.nlimit, f.nskip)


proc returnOne*(f: FindQuery): Bson =
  ## Executes the query and return the first document
  ## if `skip` has been added to the query it will honor that and skip
  ## ahead before finding the first.
  ## 
  ## Returns a single BSON document. If nothing is found,
  ## it generates a ``NotFound`` error.
  let docs = waitFor f.performFindAsync(1, f.nskip)
  if docs.len == 0:
    raise newException(NotFound, "No documents matching query were found")
  return docs[0]


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
  let docs = waitFor count.performFindAsync(1, 0)
  handleStatusReply(docs[0])
  # echo "--"
  # echo count.query
  # echo docs[0]
  return docs[0].getReplyN


proc insertMany*(db: var MongoConnection, collection: string, documents: seq[Bson], ordered: bool = true, writeConcern: Bson = nil): seq[Bson] =
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
  ##   TBD0
  ##
  ## Returns the newly inserted documents, including any ``_id`` fields auto-created.

  # 
  # insert any missing _id fields
  #
  var id = ""
  var final_docs: seq[Bson] = @[]
  for doc in documents:
    var freshCopy = doc.deepCopy()
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
    "writeConcern": if writeConcern == nil.Bson: db.writeConcern else: writeConcern
  }
  var query = makeQuery(db, "$cmd", request)
  var response = query.returnOne()
  handleStatusReply(response)
  result = final_docs


proc insertOne*(db: var MongoConnection, collection: string, document: Bson, ordered: bool = true, writeConcern: Bson = nil): Bson =
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
  ## https://docs.mongodb.com/manual/reference/method/db.collection.updateOne/
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

proc deleteMany*(db: var MongoConnection, collection: string, filter: Bson, 
                 limit: int = 0, writeConcern: Bson = nil): int =
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
      "writeConcern": if writeConcern == nil.Bson: db.writeConcern else: writeConcern
    }
    response = makeQuery(db, "$cmd", request).returnOne()
  handleStatusReply(response)
  return response.getReplyN


proc deleteOne*(db: var MongoConnection, collection: string, filter: Bson, 
                writeConcern: Bson = nil): int =
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


proc authScramSha1(pool: MongoPool, db: var MongoConnection): bool =
  ## Authenticate connection (async) using the SCRAM-SHA-1 method

  var scramClient = newScramClient[SHA1Digest]()
  let clientFirstMessage = scramClient.prepareFirstMessage(pool.username)

  #
  # request START
  #
  let requestStart = @@{
    "saslStart": 1'i32,
    "mechanism": "SCRAM-SHA-1",
    "payload": bin(clientFirstMessage),
    "autoAuthorize": 1'i32
  }
  var query = db.makeQuery("$cmd", requestStart)
  let responseStart = query.returnOne()
  if isNil(responseStart) or not isNil(responseStart["code"]):
    return false #connect failed or auth failure
  #
  # send MD5'd credentials
  #
  let
    responsePayload = binstr(responseStart["payload"])
    passwordDigest = $toMd5("$#:mongo:$#" % [pool.username, pool.password])
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


proc addConnection(pool: var MongoPool) = 
  #
  # get next largest number
  #
  var largest_so_far = 0
  for i in pool.asockets.keys:
    if i > largest_so_far:
      largest_so_far = i
  let next = largest_so_far + 1
  #
  # add one more entry
  #
  pool.asockets[next] = newAsyncSocket()
  pool.connStatus[next] = "pending TCP connect"
  #
  # establish a connection to the server
  #
  try:
    waitFor pool.asockets[next].connect(pool.hostname, asyncdispatch.Port(pool.port))
    pool.connStatus[next] = "TCP/IP connected"
  except OSError:
    pool.connStatus[next] = "failed basic TCP/IP connection"
    sleep(400)
    return
  #
  # now authenticate the connection
  #
  try:
    var authResult = true
    case pool.authMechanism:
    of "SCRAM-SHA-1":
      var tempConn = MongoConnection()
      tempConn.id = next
      tempConn.asocket = pool.asockets[next]
      tempConn.currentDatabase = pool.authDatabase
      authResult = authScramSha1(pool, tempConn)
      if authResult:
        pool.connStatus[next] = "Authenticated socket ready."
      else:
        pool.connStatus[next] = "Failed authentication."
    of "MONGODB-CR":
      pool.connStatus[next] = "[UNSUPPORTED] Unauthenticated socket ready."
    else:
      pool.connStatus[next] = "Unauthenticated socket ready."
    if authResult:
      pool.available.addLast(next) # only add it if the connection works
      pool.working.add next
  except:
    echo getCurrentExceptionMsg()
    sleep(200)
    return

proc initMongoPool(): MongoPool =
  result = MongoPool()

proc connectMongoPoolSpecific(pool: var MongoPool, url: string, minConnections = 4, maxConnections = 20) =
  #
  # parse the URL
  #
  var uDetail = parseUri(url)
  pool.originalUrl = url
  pool.hostname = uDetail.hostname
  pool.port = if uDetail.port.len > 0: parseInt(uDetail.port).uint16 else: 27017'u16
  pool.username = uDetail.username
  pool.password = uDetail.password
  pool.database = uDetail.path.extractFileName()
  pool.options = decodeQuery(uDetail)
  #
  # assign auth method details
  #
  if pool.username == "":
    pool.authMechanism = "NONE"
  else:
    if "authMechanism" in pool.options:
      let mech = pool.options["authMechanism"]
      case mech:
      of "SCRAM-SHA-1":
        pool.authMechanism = mech
      of "MONGODB-CR":
        pool.authMechanism = mech
      else:
        raise newException(CommunicationError, 
                           "MongoPool library does not currently support the " &
                           "$1 authentication mechanism.".format(mech))
    else:
      pool.authMechanism = "SCRAM-SHA-1"
    if "authSource" in pool.options:
      pool.authDatabase = pool.options["authSource"]
    else:
      pool.authDatabase = pool.database
  if pool.authDatabase == "":
    pool.authDatabase = "admin"
  pool.writeConcern = writeConcernDefault()
  #
  # establish the minimum connections
  #
  pool.minConnections = minConnections
  pool.maxConnections = maxConnections
  pool.asockets = initTable[int, AsyncSocket]()
  pool.connStatus = initTable[int, string]()
  pool.available = initDeque[int]()
  for i in 1..minConnections:
    addConnection(pool)
  #
  # check everything
  #
  if pool.available.len == 0:
    raise newException(CommunicationError, "unable to connect to $1".format(url))


proc connectMongoPool*(url: string, minConnections = 4, maxConnections = 20) =
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
  ##   determines the number database connections to start with
  ## maxConnections
  ##   determines the maximum allowed *active* connections
  ##
  ## Behind the scenes, a global variable called ``masterPool`` is created. That
  ## variable is private to this library.
  masterPool.connectMongoPoolSpecific(url, minConnections, maxConnections)


proc getMongoPoolStatus*(): string =
  ## Returns a string showing the database pool's current state.
  ##
  ## It appears in the form of:
  ##
  ## .. code::
  ##
  ##     MongoPool (default):
  ##       url: mongodb://user:2923829@mongodb.servers.somedomain.com:27017/blahblah
  ##       auth:
  ##         mechanism: SCRAM-SHA-1
  ##         database: blahblah
  ##       database: blahblah
  ##       min max: 4 20
  ##       sockets:
  ##         pool size: 4
  ##         working: 4
  ##         available: 4
  ##         [1] =   (avail) "Authenticated socket ready."
  ##         [2] =   (avail) "Authenticated socket ready."
  ##         [3] =   (avail) "Authenticated socket ready."
  ##         [4] =   (avail) "Authenticated socket ready."
  ##
  result = "MongoPool (default):\n"
  result &= "  url: $1\n".format(masterPool.originalUrl)
  result &= "  auth:\n"
  result &= "    mechanism: $1\n".format(masterPool.authMechanism)
  result &= "    database: $1\n".format(masterPool.authDatabase)
  result &= "  database: $1\n".format(masterPool.database)
  result &= "  min max: $1 $2\n".format(masterPool.minConnections, masterPool.maxConnections)
  result &= "  sockets:\n"
  result &= "    pool size: $1\n".format(masterPool.asockets.len)
  result &= "    working: $1\n".format(masterPool.working.len)
  result &= "    available: $1\n".format(masterPool.available.len)
  for index, stat in masterPool.connStatus.pairs:
    var activeStat = "   (dead)"
    if index in masterPool.working:
      activeStat = "(working)"
    if index in masterPool.available:
      activeStat = "  (avail)"
    result &= "    [$1] = $2 \"$3\"\n".format(index, activeStat, stat)


proc getNextFromSpecific(pool: var MongoPool): MongoConnection =
  if pool.available.len == 0:
    echo "adding..."
    addConnection(pool)
    echo getMongoPoolStatus()
  let index = pool.available.popFirst
  result = MongoConnection()
  result.id = index
  result.asocket = pool.asockets[index]
  result.currentDatabase = pool.database
  result.writeConcern = pool.writeConcern
  
proc getNextConnection*(): MongoConnection =
  ## Get a connection from a non-threaded context.
  ##
  ## You will want to call 'releaseConnection' when done.
  ##
  ## This is mostly used for unit testing and sample code.
  ##
  ## Returns a single connection to the database.
  result = getNextFromSpecific(masterPool)


proc getNextConnectionAsThread*(): MongoConnection {.gcsafe.} =
  ## Get a connection from the MongoDB pool from a threaded context.
  ##
  ## If the number of available connections runs out, a new connection
  ## is made. (As long as it is still below the 'maxConnections' parameter
  ## used when the pool was created.)
  ##
  ## When a thread has spawned, the code in the thread can safely get
  ## one of the pre-authenticated establlished connections from the pool.
  ## 
  ## You will want to call 'releaseConnection' with the connection
  ## before your thread terminates. Otherwise, the connection will never be
  ## release.
  ##
  ## Behind the scenes, a special 'threadvar' called 'dbThread' is "instanced"
  ## for your thread using the thread's own memory management context.
  ##
  ## Returns a single connection to the database.
  let temp = getNextFromSpecific(masterPool)
  dbThread = MongoConnection()
  dbThread.id = temp.id
  dbThread.asocket = temp.asocket
  dbThread.currentDatabase = temp.currentDatabase
  echo "db conn grabbed ", dbThread.id
  result = dbThread


proc releaseConnectionFromSpecific(pool: var MongoPool, mc: MongoConnection) = 
  pool.available.addLast(mc.id)


proc releaseConnection*(mc: MongoConnection) {.gcsafe.} =
  ## Release a live database connection back to the MongoDB pool.
  ##
  ## This is safe to call from both a threaded and non-threaded context.
  releaseConnectionFromSpecific(masterPool, mc)
  echo "db conn released ", mc.id
  return