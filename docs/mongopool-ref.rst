mongopool Reference
==============================================================================

The following are the references for mongopool.






Procs and Methods
=================


changeDatabase
---------------------------------------------------------

    .. code:: nim

        proc changeDatabase*(db: var MongoConnection, database: string) =

    *source line: 567*

    Change the current connection to use a different database than the
    one specified in the connection URL. This is rarely an approved
    behaviour of a non-admin account.
    Once changed, all future queries on this connection will be in
    reference to this database.
    
    See 'getDatabase' to get the current database name


connectMongoPool
---------------------------------------------------------

    .. code:: nim

        proc connectMongoPool*(url: string, minConnections = 4, maxConnections = 20) =

    *source line: 773*

    This procedure connects to the MongoDB database using the supplied
    `url` string. That URL should be in the form of:
    
    .. code::
    
        mongodb://[username:password@]host1[:port1][,...hostN[:portN]][/[database][?options]]
    
    It is highly recommended that you include the `database` name in the URL.
    Otherwise it will default to "admin", which is probably not right.
    If the 'username' is not present, then the connection is assumed to not
    support authentication. If an `authMechanism` option is not present, but
    a username is supplies, then the authenication is assumed to be SCRAM-SHA-1.
    If the 'authSource' option is not present, the database used just for
    authentication is assumed to be the main 'database' name.
    
    'minConnections' determines the number database connections to start with
    'maxConnections' determines the maximum allowed *active* connections
    
    Behind the scenes, a global variable called "masterPool" is created. This
    variable is private to this library.


deleteMany
---------------------------------------------------------

    .. code:: nim

        proc deleteMany*(db: var MongoConnection, collection: string, filter: Bson,

    *source line: 512*

    Delete multiple MongoDB documents.
    
    See:
    https://docs.mongodb.com/manual/reference/method/db.collection.deleteMany
    for more details.
    
    'collection' is the name of hte collection to update
    'filter' is a BSON query limiting which documents should be deleted
    'limit' restricts the number documents deleted. 0 means no limit.
    'writeConcern' TBD
    
    Returns the number of documents deleted.


deleteOne
---------------------------------------------------------

    .. code:: nim

        proc deleteOne*(db: var MongoConnection, collection: string, filter: Bson,

    *source line: 537*

    Delete one MongoDB document.
    
    See:
    https://docs.mongodb.com/manual/reference/method/db.collection.deleteOne
    for more details.
    
    'collection' is the name of hte collection to update
    'filter' is a BSON query to locate which document should be deleted
    'writeConcern' TBD
    
    This procedure is very similar to 'deleteMany' except that failure to
    locate the document will raise a NotFound error. To avoid
    NotFound error, simply use 'deleteMany' with a 'limit' set to 1.
    
    Returns the number of documents deleted, which will be 1.


find
---------------------------------------------------------

    .. code:: nim

        proc find*(db: var MongoConnection, collection: string, criteria: Bson = %*{}, fields: seq[string] = @[]): MongoCursor =

    *source line: 294*

    Starts a query to find documents in the database.
    
    'criteria' specifies the search conditions
    'fields' limits which top-level fields are returned in each document found
    
    Returns a passive 'MongoQuery' object. Nothing useful is returned until
    that object is applied to a "return" routine, such as 'returnOne' or 'returnMany'


getDatabase
---------------------------------------------------------

    .. code:: nim

        proc getDatabase*(db: var MongoConnection): string =

    *source line: 560*

    Get the current database name associated with this connection.
    This starts out as the database referenced in the connection URL,
    but can be changed with the changeDatabase procedure.


getMongoPoolStatus
---------------------------------------------------------

    .. code:: nim

        proc getMongoPoolStatus*(): string =

    *source line: 797*

    Returns a string showing the database pool's current state.
    
    It appears in the form of:
    
    .. code::
    
        MongoPool (default):
          url: mongodb://user:2923829@mongodb.servers.somedomain.com:27017/blahblah
          auth:
            mechanism: SCRAM-SHA-1
            database: blahblah
          database: blahblah
          min max: 4 20
          sockets:
            pool size: 4
            working: 4
            available: 4
            [1] =   (avail) "Authenticated socket ready."
            [2] =   (avail) "Authenticated socket ready."
            [3] =   (avail) "Authenticated socket ready."
            [4] =   (avail) "Authenticated socket ready."
    


getNextConnection
---------------------------------------------------------

    .. code:: nim

        proc getNextConnection*(): MongoConnection =

    *source line: 852*

    Get a connection from a non-threaded context.
    
    This is mostly used for unit testing and sample code.


getNextConnectionAsThread
---------------------------------------------------------

    .. code:: nim

        proc getNextConnectionAsThread*(): MongoConnection {.gcsafe.} =

    *source line: 859*

    Get a connection from the MongoDB pool from a threaded context.
    
    If the number of available connections runs out, a new connection
    is made. (As long as it is still below the 'maxConnections' parameter
    used when the pool was created.)
    
    When a thread has spawned, the code in the thread can safely get
    one of the pre-authenticated establlished connections from the pool.
    
    You will want to call 'returnConnectionAsThread' with the connection
    before your thread terminates. Otherwise, the connection will never be
    release.
    
    Behind the scenes, a special 'threadvar' called 'dbThread' is "instanced"
    for your thread using the thread's own memory management context.


insertMany
---------------------------------------------------------

    .. code:: nim

        proc insertMany*(db: var MongoConnection, collection: string, documents: seq[Bson], ordered: bool = true, writeConcern: Bson = nil): seq[Bson] =

    *source line: 416*

    Insert new documents into MongoDB.
    
    Returns the newly inserted documents, including any _id fields auto-created.
    
    If problems prevent the insertion, an error is generated.


insertOne
---------------------------------------------------------

    .. code:: nim

        proc insertOne*(db: var MongoConnection, collection: string, document: Bson, ordered: bool = true, writeConcern: Bson = nil): Bson =

    *source line: 448*

    Insert one new document into MongoDB
    
    Returns the newly inserted document, including an _id field if auto-created.
    
    If problems prevent the insertion, an error is generated.


limit
---------------------------------------------------------

    .. code:: nim

        proc limit*(f: MongoCursor, numLimit: int32): MongoCursor =

    *source line: 286*

    Limits the number of documents the query will return
    
    Returns a new query copy


releaseConnection
---------------------------------------------------------

    .. code:: nim

        proc releaseConnection*(mc: MongoConnection) {.gcsafe.} =

    *source line: 888*

    Release a live database connection back to the MongoDB pool.
    
    This is safe to call from both a threaded and non-threaded context.


replaceOne
---------------------------------------------------------

    .. code:: nim

        proc replaceOne*(db: var MongoConnection, collection: string, filter: Bson, replacement: Bson, upsert = false): int =

    *source line: 484*

    Replace one MongoDB document.
    
    See
    https://docs.mongodb.com/manual/reference/method/db.collection.updateOne/
    for more details.
    
    'collection' is the name of the collection to update
    'filter' is a query locating which document to be updated
    'replacement' is the new BSON document.
    'upsert' should be true if an insert should occur if the document is not found; otherwise set to false.
    
    You can leave the '_id' field out of the replacement document and the
    replacement will have the previous doc's '_id'.
    
    Returns a 1 if document was found matching the filter; otherwise 0.
    
    Note: it returns a 1 on a match even if the document already had the changes.


returnCount
---------------------------------------------------------

    .. code:: nim

        proc returnCount*(f: MongoCursor): int =

    *source line: 398*

    Executes the query and returns the count of documents found
    rather than the documents themselves.
    
    If no documents are found, 0 is returned.


returnMany
---------------------------------------------------------

    .. code:: nim

        proc returnMany*(f: MongoCursor): seq[Bson] =

    *source line: 378*

    Executes the query and return the matching documents.
    
    Returns a sequence of BSON documents.


returnOne
---------------------------------------------------------

    .. code:: nim

        proc returnOne*(f: MongoCursor): Bson =

    *source line: 385*

    Executes the query and return the first document
    if `skip` has been added to the query it will honor that and skip
    ahead before finding the first.
    
    Returns a single BSON document. If nothing is found,
    it generates a NotFound error.


skip
---------------------------------------------------------

    .. code:: nim

        proc skip*(f: MongoCursor, numSkip: int32): MongoCursor =

    *source line: 277*

    For a query returning multiple documents, this specifies
    how many should be skipped first.
    
    Returns a new query copy


sort
---------------------------------------------------------

    .. code:: nim

        proc sort*(f: MongoCursor, order: Bson): MongoCursor =

    *source line: 264*

    Add sorting criteria to a query
    
    this function DOES NOT affect the data on the database; merely the order
    in which found documents are presented from the query.
    
    See https://docs.mongodb.com/manual/reference/method/cursor.sort/index.html
    
    Returns a new query copy


updateMany
---------------------------------------------------------

    .. code:: nim

        proc updateMany*(db: var MongoConnection, collection: string, filter: Bson, update: Bson): int =

    *source line: 458*

    Update multiple MongoDB documents.
    
    See
    https://docs.mongodb.com/manual/reference/method/db.collection.updateMany/
    for more details.
    
    'collection' is the name of the collection to update
    'filter' is a query limiting which documents should be updated
    'update' is a BSON description of what changes to make.
    
    Returns the count of documents given the update.
    
    Note: if a document already had the new values, it is still included
    in the final count.






Table Of Contents
=================

1. `Introduction to mongopool <index.rst>`__
2. Appendices

    A. `mongopool Reference <mongopool-ref.rst>`__
    B. `mongopool/errors General Documentation <mongopool-errors-gen.rst>`__
    C. `mongopool/errors Reference <mongopool-errors-ref.rst>`__
