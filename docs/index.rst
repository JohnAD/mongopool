Introduction to mongopool
==============================================================================
ver 0.1.0

#########################################
#########################################
A simple pure-nim mongodb pooled client designed for use with threaded
applications such as `Jester <https://github.com/dom96/jester>`__.

HOW TO USE (UNTHREADED)
=======================

1. Import the library. But, you will also *really* want the `bson <https://github.com/JohnAD/bson>`__
   library as well since you will be using BSON documents.

.. code:: nim

    import mongopool
    import bson

2. Connect to MongoDB using the 'connectMongoPool' procedure.

.. code:: nim

    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")

3. Grab a connection from that pool.

.. code:: nim

    var db = getNextConnection()

4. Use it to do things! See the section called `BASIC CRUD <#basic-crud>`__ for quick examples.

.. code:: nim

    var doc = db.find("mycollection", @@{"name": "jerry"}).returnOne()

5. Release the connection when done.

.. code:: nim

    releaseConnection(db)

HOW TO USE (THREADED)
=====================

The whole point of this library is threaded application use. The biggest
change is that the connection is pulled using ``getNextConnectionAsThread``
instead of ``getNextConnection``. Of course, that will only work from inside
the thread. Here is an example that uses Jester to make a web site:

.. code:: nim

    import jester
    import mongopool
    import bson

    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")

    routes:
      get "/":
        #
        # get a connection:
        #
        var db = getNextConnectionAsThread()
        #
        # doing something with it:
        #
        var doc = db.find("temp").returnOne()
        #
        # releasing it before the thread closes
        #
        releaseConnection(db)
        #
        resp "doc = " & $doc

BASIC CRUD
==========

Some quick examples of how to Create, Read, Update, and Delete and their
related functions. See the appendix references for more details.

CREATE
======

Example:

.. code:: nim

    import mongopool
    import bson
    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
    var db = getNextConnection()

    let joe = @@{
      "name": "Joe",
      "age": 42
    }
    let personFinal = db.insertOne("people", joe)
    echo "$1 was given an _id of $2".format(personFinal["name"], personFinal["_id"])

    releaseConnection(db)

related functions:
`insertMany <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#insertmany>`__,
`insertOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#insertone>`__

READ (FIND)
-----------

.. code:: nim

    import mongopool
    import bson
    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
    var db = getNextConnection()

    var docs = db.find("people", @@{"age": {"$gt": 21}}).sort(@@{"name": 1}).limit(10).returnMany()

    for doc in docs:
      echo "name: $1, age $2".format(doc["name"], doc["age"])

    releaseConnection(db)

related functions:

* to start the query: `find <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#find>`__

* to modify the query:
  `limit <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#limit>`__,
  `skip <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#skip>`__,
  `sort <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#sort>`__

* to get results from the query:
  `returnCount <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returncount>`__,
  `returnMany <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returnmany>`__,
  `returnOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#returnone>`__

UPDATE
------

.. code:: nim

    import mongopool
    import bson
    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
    var db = getNextConnection()

    var joe = db.find("people", @@{"name": "Joe"}).returnOne()
    joe["age"] = 43
    let ctr = db.replaceOne("people", @@{"_id": joe["_id"]}, joe)
    if ctr == 1:
      echo "change made!"

    releaseConnection(db)

related functions:
`replaceOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#replaceone>`__,
`deleteOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#deleteone>`__

DELETE
------

.. code:: nim

    import mongopool
    import bson
    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
    var db = getNextConnection()

    var ctr = db.deleteMany("people", @@{"name": "Larry"})
    echo "$1 people named Larry removed.".format(ctr)

    releaseConnection(db)

related functions:
`deleteMany <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#deletemany>`__,
`deleteOne <https://github.com/JohnAD/mongopool/blob/master/docs/mongopool-ref.rst#deleteone>`__



Table Of Contents
=================

1. `Introduction to mongopool <index.rst>`__
2. Appendices

    A. `mongopool Reference <mongopool-ref.rst>`__
    B. `mongopool/errors Reference <mongopool-errors-ref.rst>`__
