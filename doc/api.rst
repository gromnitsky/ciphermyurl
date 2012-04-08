.. include:: api.vars.rest

===============
|name| API Spec
===============

:Last Update: Time-stamp: <2012-04-08 22:33:35 EEST>
:API Version: |apiversion|

.. contents::
			  
Terminology
-----------

Client
  A peace of software that interacts with |name| back-end. |name| itself
  has a web-based client and it uses this API just as any other
  client without any 'secret' knowledge. 

Slot
  An unsigned integer > 0. The number of slots roughly corresponds to a
  number of entries in |name| DB. Slot is generated automatically--it is
  not possible to choose a 'preferred' integer. Slots are public
  information.

  1 slot contains 1 'data' object.

Data
  A UTF-8 string with size of 11-512 characters (not bytes). The
  contents of the string is irrelevant. If, however, the string contains
  a valid URI and nothing else, |name| client will try to redirect user
  to that URI automatically. Such behaviour is advised for other clients too.

  Data will be 'cleaned' by |name| to prevent naive clients of
  misbehaving. For example, the input::

    <script>alert('âÕÇÁÇÁ')</script>

  internally will be transformed to::

	&lt;script&gt;alert('âÕÇÁÇÁ')&lt;/script&gt;

Password
  An ASCII string of 8-512 bytes size. Allowed chars are ``[a-zA-Z0-9]``.

Unpack
  An API command that client use to receive data from the server.

Public Key & Private Key
  Required for some client commands.
  
Pack
  An API command that client use to post data to the server.


Transport
---------

HTTP 1.1 with persistent connections. Server will close a socket if a
client will provide a bad request.

Protocol
--------

Th protocol **is not** RESTfull.

Visioning of the protocol API is similar to Rubygems scheme.

Authentication
--------------

Some API commands require authentication. To write a client for a |name|
you'll need a pair of public and private keys. To obtain those keys
`email me
<mailto:flower.henry@yahoo.com?Subject=CipherMyUrl%20keys%20request>`_. (Do
not change a title of a email.)


Commands
--------

Pack
````

HTTP POST to ``/api/0.0.1/pack``. Body of a request is a JSON
with pair names:

* ``data``
* ``pw``
* ``kpublic``
* ``kprivate``

Server returns:

================ ============ ================= =======================
HTTP Status Code Content-Type Body              Which means
================ ============ ================= =======================
201              text/plain   Slot              OK
401              text/html    Error description Client is unauthorized
400              text/html    Error description Bad request
500              text/html    Error description Server's internal error
================ ============ ================= =======================

An error description in plan text can also be obtained from
``X-Ciphermyurl-Error`` header.

Examples
::::::::

Client sends invalid JSON (lines are wrapped with ``\``)::

  % curl -i --data-binary '{data: 'http://google.com', pw: \
  12345678, kpublic: "123", kprivate "456"}' localhost:9393/api/0.0.1/pack

  HTTP/1.1 400 Bad Request 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/html;charset=utf-8
  X-Ciphermyurl-Error: 743: unexpected token at '{data: \
  http://google.com, pw: 12345678, kpublic: "123", kprivate "456"}'
  Content-Length: 119
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sun, 08 Apr 2012 19:19:50 GMT
  Connection: Keep-Alive

  <h1>400</h1>
  Error: 743: unexpected token at '{data: http://google.com, pw: 12345678,
  kpublic: "123", kprivate "456"}'

Client sends a valid JSON but with invalid keys::

  % curl -i --data-binary '{"data": 12345678912, "pw": 12345678, \
  "kpublic": "123", "kprivate": "456"}' localhost:9393/api/0.0.1/pack

  HTTP/1.1 401 Unauthorized 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/html;charset=utf-8
  X-Ciphermyurl-Error: invalid public or private key
  Content-Length: 50
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sun, 08 Apr 2012 19:22:30 GMT
  Connection: Keep-Alive

  <h1>401</h1>
  Error: invalid public or private key

A valid request with a new slot as a result::

  % curl -i --data-binary '{"data": 12345678912, "pw": 12345678, \
  "kpublic": "c575ad09-81b0-11e1-ab8d-000c29fa7daf", \
  "kprivate": "bb004c88dfa17f56563f7d934d53c90cd5677a8"}' \
  localhost:9393/api/0.0.1/pack

  HTTP/1.1 201 Created 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/plain;charset=utf-8
  Content-Length: 1
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sun, 08 Apr 2012 19:25:37 GMT
  Connection: Keep-Alive

  42


Unpack
``````

HTTP GET to ``/api/0.0.1/unpack``. Required parameters:

* ``slot``
* ``pw``

Auth is unnecessary. Server returns:

================ ============ ================= =======================
HTTP Status Code Content-Type Body              Which means
================ ============ ================= =======================
200              text/plain   Data              OK
400              text/html    Error description Bad request
403              text/html    Error description Invalid password
404              text/html    Error description Slot not found
500              text/html    Error description Server's internal error
================ ============ ================= =======================

An error description in plan text can also be obtained from
``X-Ciphermyurl-Error`` header.

Examples
::::::::

Client sends invalid password::

  % curl -i 'http://localhost:9393/api/0.0.1/unpack?slot=123&pw=idontremember'

  HTTP/1.1 403 Forbidden 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/html;charset=utf-8
  X-Ciphermyurl-Error: invalid password
  Content-Length: 37
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sat, 07 Apr 2012 19:05:47 GMT
  Connection: Keep-Alive

  <h1>403</h1>
  Error: invalid password

A valid request::

  % curl -i 'http://localhost:9393/api/0.0.1/unpack?slot=123&pw=12345678'

  HTTP/1.1 200 OK 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/plain;charset=utf-8
  Content-Length: 128
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sat, 07 Apr 2012 19:06:39 GMT
  Connection: Keep-Alive

  Hi mom.

Del
```

HTTP DELETE to ``/api/0.0.1/del``. Required parameters:

* ``slot``
* ``pw``

Server returns:

================ ============ ================= =======================
HTTP Status Code Content-Type Body              Which means
================ ============ ================= =======================
200              text/plain   (empty)           OK
400              text/html    Error description Bad request
403              text/html    Error description Client is unauthorized
500              text/html    Error description Server's internal error
================ ============ ================= =======================

This command behaves like an idempotent one.

Examples
::::::::

Authorization error::

  % curl -i -X DELETE 'http://localhost:9393/api/0.0.1/del?slot=1&pw=oops'

  HTTP/1.1 403 Forbidden 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/html;charset=utf-8
  X-Ciphermyurl-Error: invalid password
  Content-Length: 37
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sun, 08 Apr 2012 19:28:30 GMT
  Connection: Keep-Alive

  <h1>403</h1>
  Error: invalid password

A valid request::

  % curl -i -X DELETE 'http://localhost:9393/api/0.0.1/del?slot=1&pw=12345678'

  HTTP/1.1 200 OK 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/plain;charset=utf-8
  Content-Length: 0
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sun, 08 Apr 2012 19:29:11 GMT
  Connection: Keep-Alive
