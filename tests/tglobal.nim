import unittest

import mongopool, bson

suite "Non-threaded test":
  test "connect and do CRUD":

    connectMongoPool("mongodb://127.0.0.1/test")    

    var db = getNextConnection()

    check db.getDatabase() == "test"

    let joe = @@{
      "name": "Joe",
      "age": 42
    }

    var joeReal = db.insertOne("people", joe)

    check joeReal["name"] == "Joe"
    check joeReal["age"] == 42

    joeReal["age"] = toBson(43)

    let updateCtr = db.replaceOne("people", @@{"_id": joeReal["_id"]}, joeReal)

    check updateCtr == 1

    let delCtr = db.deleteMany("people", @@{"_id": joeReal["_id"]})

    check delCtr == 1
