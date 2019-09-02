mongopool/errors Reference
==============================================================================

The following are the references for mongopool/errors.



Types
=====



.. _CommunicationError.type:
CommunicationError
---------------------------------------------------------

    .. code:: nim

        CommunicationError* = object of Exception


    *source line: `2 <../src/mongopool/errors.nim#L2>`__ *

    Raises on communication problems with MongoDB server


.. _MongoPoolError.type:
MongoPoolError
---------------------------------------------------------

    .. code:: nim

        MongoPoolError* = object of Exception


    *source line: `5 <../src/mongopool/errors.nim#L5>`__ *

    Base exception for nimongo error (for simplifying error handling)


.. _NotFound.type:
NotFound
---------------------------------------------------------

    .. code:: nim

        NotFound* = object of MongoPoolError


    *source line: `8 <../src/mongopool/errors.nim#L8>`__ *

    Raises when querying of one documents returns empty result


.. _ReplyFieldMissing.type:
ReplyFieldMissing
---------------------------------------------------------

    .. code:: nim

        ReplyFieldMissing* = object of MongoPoolError


    *source line: `11 <../src/mongopool/errors.nim#L11>`__ *

    Raises when reqired field in reply is missing









Table Of Contents
=================

1. `Introduction to mongopool <index.rst>`__
2. Appendices

    A. `mongopool Reference <mongopool-ref.rst>`__
    B. `mongopool/errors Reference <mongopool-errors-ref.rst>`__
