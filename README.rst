Introduction to mongopool
==============================================================================

.. image:: https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png
   :height: 34
   :width: 131
   :alt: nimble

#########################################
#########################################
MONGOPOOL

A simple pure-nim mongodb pooled client designed for use with threaded
applications such as "Jester".

HOW TO USE (UNTHREADED)
-----------------------

1. Import the library (duh.) But, you will also *really* want the 'bson'
   library as well since you will be sending the documents as BSON.

.. code:: nim

    import mongopool
    import bson

2. Connect to MongoDB using the 'connectMongoPool' procedure.

.. code:: nim

    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")

3. Grab a connection from that pool.

.. code:: nim

    var db = getNextConnection()

4. Use it to do things! See the section called "BASIC CRUD" for quick examples.

.. code:: nim

    var doc = db.find("mycollection", %*{"name": "jerry"}).returnOne()

5. Release the connection when done.

.. code:: nim

    releaseConnection(db)

HOW TO USE (THREADED)
---------------------

The whole point of this library is threaded application use. The biggest
change is that the connection is pulled using 'getNextConnectionAsThread'
instead of 'getNextConnection'. Of course, that will only work from inside
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
----------

Some quick examples of how to Create, Read, Update, and Delete. See the
appendix reference for more details.

CREATE
======

.. code:: nim

    import mongopool
    import bson
    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
    var db = getNextConnection()

    let joe = %*{
      "name": "Joe",
      "age": 42
    }
    let personFinal = db.insertOne("people", joe)
    echo "$1 was given an _id of $2".format(personFinal["name"], personFinal["_id"])

    releaseConnection(db)

READ (FIND)
===========

.. code:: nim

    import mongopool
    import bson
    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
    var db = getNextConnection()

    var docs = db.find("people", %*{"age": {"$gt": 21}}).sort(%*{"name": 1}).limit(10).returnMany()

    for doc in docs:
      echo "name: $1, age $2".format(doc["name"], doc["age"])

    releaseConnection(db)

UPDATE
======

.. code:: nim

    import mongopool
    import bson
    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
    var db = getNextConnection()

    var joe = db.find("people", %*{"name": "Joe"}).returnOne()
    joe["age"] = 43
    let ctr = db.replaceOne(%*{"_id": joe["_id"]}, joe)
    if ctr == 1:
      echo "change made!"

    releaseConnection(db)

DELETE
======

.. code:: nim

    import mongopool
    import bson
    connectMongoPool("mongodb://someone:secret@mongo.domain.com:27017/abc")
    var db = getNextConnection()

    var ctr = db.deleteMany("people", %*{"name": "Larry"})
    echo "$1 people named Larry removed.".format(ctr)

    releaseConnection(db)




Table Of Contents
=================

1. `Introduction to mongopool <docs/index.rst>`__
2. Appendices

    A. `mongopool Reference <docs/mongopool-ref.rst>`__
    B. `mongopool/errors General Documentation <docs/mongopool-errors-gen.rst>`__
    C. `mongopool/errors Reference <docs/mongopool-errors-ref.rst>`__
