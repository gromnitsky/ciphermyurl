.. include:: api.vars.rest

===============
|name| API Spec
===============

:Last Update: Time-stamp: <2012-04-07 22:49:17 EEST>
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

Auth
  Some additional string that allows a server to allow or disallow
  client to perform some operation.

Unpack
  An API command that client use to receive data from the server.

Keyshash
  Auth string.
  
Pack
  An API command to a server that must contain data, a password and a
  keyshash.


Transport
---------

HTTP 1.1 with persistent connections. Server will close a socket if a
client will provide a bad request.

Protocol
--------

Th protocol **is not** RESTfull.

Visioning of the protocol API is similar to Rubygems scheme.

Auth
----

Some API commands require auth. To write a client for a |name| you'll
need a pair of public and private keys. To obtain those keys `email me
<mailto:flower.henry@yahoo.com?Subject=CipherMyUrl%20keys%20request>`_. (Do
not change a title of a email.)

Once you have a keys pair, you'll need a keyshash. Keyshash is a sha256
of public key and private key (in that order). For example, if you are
using Ruby::

  require 'digest/sha2'

  module MyAuth
	def self.keyshash(kpubic, kprivate)
	  Digest::SHA256.hexdigest(kpubic + kprivate)
	end

	...
  end

Commands
--------

Pack
````

HTTP POST to ``/api/0.0.1/pack``. Body of a request is a JSON
with pair names:

* ``data``
* ``pw``
* ``keyshash``

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

  % curl -i --data-binary '{data: 'http://google.com', pw: 12345678,\
  keyshash:\
  "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b"}'\
  localhost:9393/api/0.0.1/pack
  
  HTTP/1.1 400 Bad Request 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/html;charset=utf-8
  X-Ciphermyurl-Error: 743: unexpected token at '{data:
  http://google.com,\
  pw: 12345678, keyshash:\
  "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b"}'
  Content-Length: 165
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sat, 07 Apr 2012 18:47:26 GMT
  Connection: Keep-Alive

  <h1>400</h1>
  Error: 743: unexpected token at '{data: http://google.com, pw:
  12345678,\
  keyshash:\
  "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b"}'

Client sends a valid JSON but with invalid keyshash::

  % curl -i --data-binary '{"data": 12345678912, "pw": 12345678,\
  "keyshash": "6e7ac725191d7ea69f2555c47dd28680"}'\
  localhost:9393/api/0.0.1/pack
  
  HTTP/1.1 401 Unauthorized 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/html;charset=utf-8
  X-Ciphermyurl-Error: keyshash is missing in our DB
  Content-Length: 54
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sat, 07 Apr 2012 18:54:36 GMT
  Connection: Keep-Alive

  <h1>401</h1>
  Error: keyshash is missing in our DB

A valid request with a new slot as a result::

  % curl -i --data-binary '{"data": 12345678912, "pw": 12345678,\
  "keyshash":\
  "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b"}'\
  localhost:9393/api/0.0.1/pack

  HTTP/1.1 201 Created 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/plain;charset=utf-8
  Content-Length: 1
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sat, 07 Apr 2012 18:58:18 GMT
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
* ``keyshash``

The idea is you as a client author can delete any user-created slots in
case slots contain some nasty, offensive data and slot+password for such
data became publicly known.

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
  
  % curl -i -X DELETE \
  'http://localhost:9393/api/0.0.1/del?slot=1&keyshash=oops'

  HTTP/1.1 403 Forbidden 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/html;charset=utf-8
  X-Ciphermyurl-Error: invalid keyshash
  Content-Length: 37
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sat, 07 Apr 2012 19:19:04 GMT
  Connection: Keep-Alive

  <h1>403</h1>
  Error: invalid keyshash

A valid request::

  % curl -i -X DELETE \
  'http://localhost:9393/api/0.0.1/del?slot=1&keyshash=\
  6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b'

  HTTP/1.1 200 OK 
  X-Frame-Options: sameorigin
  X-Xss-Protection: 1; mode=block
  Content-Type: text/plain;charset=utf-8
  Content-Length: 0
  Server: WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)
  Date: Sat, 07 Apr 2012 19:20:09 GMT
  Connection: Keep-Alive

