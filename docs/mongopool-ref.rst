mongopool Reference
==============================================================================

The following are the references for mongopool.






Procs, Methods, Iterators
=========================


.. _changeDatabase.p:
changeDatabase
---------------------------------------------------------

    .. code:: nim

        proc changeDatabase*(db: var MongoConnection, database: string) =

    source line: `649 <../src/mongopool.nim#L649>`__

    Change the current connection to use a different database than the
    one specified in the connection URL. This is rarely approved
    behaviour for non-admin accounts.
    Once changed, all future queries on this connection will be in
    reference to this database (until the thread closes).
    
    See ``getDatabase`` to get the current database name


.. _connectMongoPool.p:
connectMongoPool
---------------------------------------------------------

    .. code:: nim

        proc connectMongoPool*(url: string, minConnections = 4, maxConnections = 20) {.gcsafe.} =

    source line: `799 <../src/mongopool.nim#L799>`__

    This procedure connects to the MongoDB database using the supplied
    `url` string. That URL should be in the form of:
    
    .. code::
    
        mongodb://[username:password@]host1[:port1][,...hostN[:portN]][/[database][?options]]
    
    It is recommended that you include the `database` name in the URL.
    Otherwise, it will default to "admin", which is probably not right.
    If the ``username`` is not present, then the connection is assumed to not
    support authentication. If an ``authMechanism`` option is not present, but
    a ``username`` is supplied, then the authenication is assumed to be SCRAM-SHA-1.
    If the ``authSource`` option is not present, the database used just for
    authentication is assumed to be the main ``database`` name.
    
    url
      url of the MongoDB server to connect to
    minConnections
      determines the number database connections to start with
    maxConnections
      determines the maximum allowed *active* connections
    
    Behind the scenes, a global variable called ``masterPool`` is created. That
    variable is private to this library.


.. _deleteMany.p:
deleteMany
---------------------------------------------------------

    .. code:: nim

        proc deleteMany*(db: var MongoConnection, collection: string, filter: Bson, limit: int = 0, writeConcern: Bson = nil): int =

    source line: `587 <../src/mongopool.nim#L587>`__

    Deletes multiple MongoDB documents.
    
    See:
    https://docs.mongodb.com/manual/reference/method/db.collection.deleteMany
    for more details.
    
    collection
      the name of hte collection to update
    filter
      a BSON query limiting which documents should be deleted
    limit
      restricts the number documents deleted. 0 means no limit.
    writeConcern
      TBD
    
    Returns the number of documents deleted.


.. _deleteOne.p:
deleteOne
---------------------------------------------------------

    .. code:: nim

        proc deleteOne*(db: var MongoConnection, collection: string, filter: Bson, writeConcern: Bson = nil): int =

    source line: `615 <../src/mongopool.nim#L615>`__

    Deletes one MongoDB document.
    
    See:
    https://docs.mongodb.com/manual/reference/method/db.collection.deleteOne
    for more details.
    
    collection
      the name of the collection to update
    filter
      a BSON query to locate which document should be deleted
    writeConcern
      TBD
    
    This procedure is very similar to ``deleteMany`` except that failure to
    locate the document will raise a ``NotFound`` error. To avoid the
    ``NotFound`` error, simply use ``deleteMany`` with a ``limit`` set to 1.
    
    Returns the number of documents deleted, which will be 1.


.. _find.p:
find
---------------------------------------------------------

    .. code:: nim

        proc find*(db: var MongoConnection, collection: string, criteria: Bson = @@{}, fields: seq[string] = @[]): FindQuery =

    source line: `343 <../src/mongopool.nim#L343>`__

    Starts a query to find documents in the database.
    
    collection
      The collection to search
    criteria
      specifies the search conditions
    fields
      limits which top-level fields are returned in each document found
    
    Returns a passive 'FindQuery' object. Nothing useful is returned until
    that object is applied to a "return" routine, such as ``returnOne``,
    ``returnMany``, or ``returnCount``.


.. _getDatabase.p:
getDatabase
---------------------------------------------------------

    .. code:: nim

        proc getDatabase*(db: var MongoConnection): string =

    source line: `640 <../src/mongopool.nim#L640>`__

    Get the current database name associated with this connection.
    This starts out as the database referenced in the connection URL,
    but can be changed with the changeDatabase procedure.
    
    Returns the name of the current database.


.. _getMongoPoolStatus.p:
getMongoPoolStatus
---------------------------------------------------------

    .. code:: nim

        proc getMongoPoolStatus*(): string {.gcsafe.} =

    source line: `886 <../src/mongopool.nim#L886>`__

    Returns a string showing the database pool's current state.
    
    An attempt is made to cover any password in the url.
    
    It appears in the form of:
    
    .. code::
    
        mongopool (default):
          url: mongodb://user:<password>@mongodb.servers.somedomain.com:27017/blahblah
          auth:
            mechanism: SCRAM-SHA-1
            database: blahblah
          database: blahblah
          min max: 4 20
          sockets:
            pool size: 4
            working: 4
            available: 4
            last used: 1
            [1] =   (avail) "Authenticated socket ready."
            [2] =   (avail) "Authenticated socket ready."
            [3] =   (avail) "Authenticated socket ready."
            [4] =   (avail) "Authenticated socket ready."
    


.. _getNextConnection.p:
getNextConnection
---------------------------------------------------------

    .. code:: nim

        proc getNextConnection*(): MongoConnection {.gcsafe.} =

    source line: `955 <../src/mongopool.nim#L955>`__

    Get a connection from the MongoDB pool.
    
    If the number of available connections runs out, a new connection
    is made. (As long as it is still below the 'maxConnections' parameter
    used when the pool was created.)
    
    When a thread has spawned, the code in the thread can safely get
    one of the pre-authenticated establlished connections from the pool.
    
    You will want to call 'releaseConnection' with the connection
    before your thread terminates. Otherwise, the connection will never be
    release.
    
    If you are in the context of a tread, a special threadvar called
    ``dbThread`` is "instanced" for your thread using the thread's own memory
    management context. Otherwise, a new instance is called.
    
    Returns a single connection to the database.


.. _insertMany.p:
insertMany
---------------------------------------------------------

    .. code:: nim

        proc insertMany*(db: var MongoConnection, collection: string, documents: seq[Bson], ordered: bool = true, writeConcern: Bson = nil): seq[Bson] =

    source line: `470 <../src/mongopool.nim#L470>`__

    Insert new documents into MongoDB.
    
    If problems prevent the insertion, an error is generated.
    
    collection
      the collection to receive the new document(s)
    documents
      a sequence of BSON documents to be inserted
    ordered
      if true, the database should insert them one-after-the-next
    writeConcern
      TBD
    
    Returns the newly inserted documents, including any ``_id`` fields auto-created.


.. _insertOne.p:
insertOne
---------------------------------------------------------

    .. code:: nim

        proc insertOne*(db: var MongoConnection, collection: string, document: Bson, ordered: bool = true, writeConcern: Bson = nil): Bson =

    source line: `511 <../src/mongopool.nim#L511>`__

    Insert one new document into MongoDB
    
    Returns the newly inserted document, including an _id field if auto-created.
    
    collection
      the collection to receive the new document(s)
    document
      the BSON documents to be inserted
    
    If problems prevent the insertion, an error is generated.


.. _limit.p:
limit
---------------------------------------------------------

    .. code:: nim

        proc limit*(f: FindQuery, numLimit: int32): FindQuery =

    source line: `335 <../src/mongopool.nim#L335>`__

    Limits the number of documents the query will return
    
    Returns a new query copy


.. _releaseConnection.p:
releaseConnection
---------------------------------------------------------

    .. code:: nim

        proc releaseConnection*(mc: MongoConnection) {.gcsafe.} =

    source line: `992 <../src/mongopool.nim#L992>`__

    Release a live database connection back to the MongoDB pool.
    
    This is safe to call from both a threaded and non-threaded context.


.. _replaceOne.p:
replaceOne
---------------------------------------------------------

    .. code:: nim

        proc replaceOne*(db: var MongoConnection, collection: string, filter: Bson, replacement: Bson, upsert = false): int =

    source line: `555 <../src/mongopool.nim#L555>`__

    Replace one MongoDB document.
    
    See
    https://docs.mongodb.com/manual/reference/method/db.collection.updateOne/
    for more details.
    
    collection
      the name of the collection to update
    filter
      a query locating which document to be updated
    replacement
      the new BSON document.
    upsert
      should be true if an insert should occur if the document is not found; otherwise set to false.
    
    You can leave the ``_id`` field out of the replacement document and the
    replacement will have the previous doc's ``_id``.
    
    Returns a 1 if document was found matching the filter; otherwise 0.
    
    Note: it returns a 1 on a match even if the document already had the changes.


.. _returnCount.p:
returnCount
---------------------------------------------------------

    .. code:: nim

        proc returnCount*(f: FindQuery): int =

    source line: `452 <../src/mongopool.nim#L452>`__

    Executes the query and returns the count of documents found
    (rather than the documents themselves).
    
    If no documents are found, 0 is returned.


.. _returnMany.p:
returnMany
---------------------------------------------------------

    .. code:: nim

        proc returnMany*(f: FindQuery): seq[Bson] =

    source line: `432 <../src/mongopool.nim#L432>`__

    Executes the query and returns the matching documents.
    
    Returns a sequence of BSON documents.


.. _returnOne.p:
returnOne
---------------------------------------------------------

    .. code:: nim

        proc returnOne*(f: FindQuery): Bson =

    source line: `439 <../src/mongopool.nim#L439>`__

    Executes the query and return the first document
    if `skip` has been added to the query it will honor that and skip
    ahead before finding the first.
    
    Returns a single BSON document. If nothing is found,
    it generates a ``NotFound`` error.


.. _skip.p:
skip
---------------------------------------------------------

    .. code:: nim

        proc skip*(f: FindQuery, numSkip: int32): FindQuery =

    source line: `326 <../src/mongopool.nim#L326>`__

    For a query returning multiple documents, this specifies
    how many should be skipped first.
    
    Returns a new ``FindQuery`` copy.


.. _sort.p:
sort
---------------------------------------------------------

    .. code:: nim

        proc sort*(f: FindQuery, order: Bson): FindQuery =

    source line: `312 <../src/mongopool.nim#L312>`__

    Add sorting criteria to a query.
    
    this function DOES NOT affect the data on the database; merely the order
    in which found documents are presented from the query.
    
    order
      See https://docs.mongodb.com/manual/reference/method/cursor.sort/index.html
    
    Returns a new ``FindQuery`` copy


.. _updateMany.p:
updateMany
---------------------------------------------------------

    .. code:: nim

        proc updateMany*(db: var MongoConnection, collection: string, filter: Bson, update: Bson): int =

    source line: `526 <../src/mongopool.nim#L526>`__

    Update multiple MongoDB documents.
    
    See
    https://docs.mongodb.com/manual/reference/method/db.collection.updateMany/
    for more details.
    
    collection
      the name of the collection to update
    filter
      a query limiting which documents should be updated
    update
      a BSON description of what changes to make.
    
    Returns the count of documents given the update.
    
    Note: if a document already had the new values, it is still included
    in the final count.







Table Of Contents
=================

1. `Introduction to mongopool <index.rst>`__
2. Appendices

    A. `mongopool Reference <mongopool-ref.rst>`__
    B. `mongopool/errors Reference <mongopool-errors-ref.rst>`__
