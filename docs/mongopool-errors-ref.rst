mongopool/errors Reference
==============================================================================

The following are the references for mongopool/errors.



Types
=====



CommunicationError
---------------------------------------------------------

    .. code:: nim

        CommunicationError* = object of Exception


    *source line: 2*

    Raises on communication problems with MongoDB server


MongoPoolError
---------------------------------------------------------

    .. code:: nim

        MongoPoolError* = object of Exception


    *source line: 5*

    Base exception for nimongo error (for simplifying error handling)


NotFound
---------------------------------------------------------

    .. code:: nim

        NotFound* = object of MongoPoolError


    *source line: 8*

    Raises when querying of one documents returns empty result


ReplyFieldMissing
---------------------------------------------------------

    .. code:: nim

        ReplyFieldMissing* = object of MongoPoolError


    *source line: 11*

    Raises when reqired field in reply is missing









Table Of Contents
=================

1. `Introduction to mongopool <index.rst>`__
2. Appendices

    A. `mongopool Reference <mongopool-ref.rst>`__
    B. `mongopool/errors General Documentation <mongopool-errors-gen.rst>`__
    C. `mongopool/errors Reference <mongopool-errors-ref.rst>`__
