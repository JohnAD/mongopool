type
  CommunicationError* = object of Exception
  ## Raises on communication problems with MongoDB server

  MongoPoolError* = object of Exception
  ## Base exception for nimongo error (for simplifying error handling)  

  NotFound* = object of MongoPoolError
  ## Raises when querying of one documents returns empty result

  MongoPoolCapacityReached* = object of MongoPoolError
  ## Raises when querying of one documents returns empty result

  ReplyFieldMissing* = object of MongoPoolError
  ## Raises when reqired field in reply is missing
