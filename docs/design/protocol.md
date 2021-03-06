# Communication Protocol
## Quick References
### Actions

Name             | Namespace | Parameters                                                                | Description
---------------- | --------- | ------------------------------------------------------------------------- | ------------------------------------------------------------
`'register'`     | `'/'`     | `id: ID, cb: PERMISSION_CB`                                               | [Declare an endpoint](#action-declare-an-endpoint)
`'refresh'`      | `'/'`     | `tokens: Tokens, cb: REFRESH_CB`                                          | [Refresh token](#action-refresh-token)
`'list'`         | `'/'`     | `cb: LIST_CB`                                                             | [List connected endpoints](#action-list-connected-endpoints)
`'log'`          | `'/log'`  | `type: LogTypeEnum, args: Array`                                          | [Write a log entry](#action-write-a-log-entry)
`'list_modules'` | `'/rpc'`  | `cb: MODULE_CB`                                                           | [List modules](#action-list-modules)
`'require'`      | `'/rpc'`  | `moduleName: string, cb: REQUIRE_CB`                                      | [Require module](#action-require-module)
`'call'`         | `'/rpc'`  | `moduleName: string, methodName: string, args: Array<object>, cb: RPC_CB` | [Call method](#action-call-method)

### Events

Name                    | Namespace | Arguments                  | Description
----------------------- | --------- | -------------------------- | -------------------------------------------------------------------------------------------------------------
`'endpoint_connect'`    | `'/'`     | `endpoint: Endpoint`       | [Fired when a new endpoint is connected](#event-endpoint_connect)
`'endpoint_update'`     | `'/'`     | `endpoint: Endpoint`       | [Fired when an endpoint is updated](#event-endpoint_update)
`'endpoint_disconnect'` | `'/'`     | `endpoint: Endpoint`       | [Fired when an endpoint is disconnected](#event-endpoint_disconnect)
`'log'`                 | `'/log'`  | `entry: LogEntry`          | [Fired when a log entry is received](#event-log)
`'history'`             | `'/log'`  | `entries: Array<LogEntry>` | [Fired when a socket is connected, with all history log entries up-to a pre-configured count](#event-history)

## Definitions
### Terminology

Term             | Definition
---------------- | --------------------------------------------------------------------------------------
Asset Server     | Web server that hosts all extension assets (e.g. UI, device-side script)
Socket Server    | Socket.io server
Discovery Server | A known server that can re-direct client's user-agent to the atom-entanglement servers
Endpoint         | A device user-agent instance or an Atom editor instance
Channel          | A socket.io namespace
Extension        | An Atom package that provide additional features
RPC              | Remote procedure call

### Channels
All communication described in this document happens over sockets. Available channels are:

Channel | Namespace | Description
------- | --------- | -----------------------
Root    | `/`       | Used for authentication
Server  | `/server` | Server control
Log     | `/log`    | Logging
RPC     | `/rpc`    | RPC
Atom    | `/atom`   | Atom-only operations
Device  | `/device` | Device-only operations

### Verbs
The following verbs are used to describe an action:

Verb       | Type      | Description
---------- | --------- | ------------------------------------
`GET`      | HTTP      |
`POST`     | HTTP      |
`REDIRECT` | HTTP      |
`CONNECT`  | socket.io | `io.connect(url)`
`EMIT`     | socket.io | `socket.emit(evt, payload)`
`TO`       | socket.io | `socket.to(room).emit(evt, payload)`
`ON`       | socket.io | `socket.on(evt, handler)`

### Typing
All variables are typed in the following convention:

```coffee
identifier: Type
```

## Service Discovery
Asset server and socket server will be running on user's `localhost` (assuming its IP addresses cannot be resolved via DNS or other scheme).

Devices (usually in the same LAN environment) need to know the host's IP address to  establish a connection.

A light-weighted HTTP service discovery scheme [Miao](https://github.com/akfish/miao) is used to simplify the discovery process. All possible IP addresses of the server will be encoded into a query string. The discovery server hosts a static page, which will parse the query string and ping each IP addresses. Once resolved, the browser will be redirected to the server.

For user's convenience, atom-entanglement generates a QR code of the service discovery URL.

### Action: Discovery atom-entanglement server

```coffee
GET http://catx.me/miao/
```

#### Parameters
See [Miao/References/Options](https://github.com/akfish/miao#options)

#### Response

```coffee
REDIRECT RESOLVED_HOST
```

## Authentication
### Overview
Atom-entanglement's authentication scheme is role-based. An endpoint must declare its role for the server to issue an access token. The role of an endpoint determines to which channels it has access.

```
+-----------+                       +--------------+
|           |                       |              |
| Endpoint  | +--------(A)--------> | Root Channel |
|           |                       |              |
|           | <--------(B1)-------+ |              |
|           |                       |              |
|           | <--------(B2)-------+ |              |
|           |                       +--------------+
|           |                                       
|           |                                       
|           |                       +--------------+
|           |                       |              |
|           | +--------(C)--------> | Allowed      |
|           |                       | Channel      |
|           | <--------(D1)-------+ |              |
|           |                       |              |
|           | <--------(D2)-------+ |              |
|           |                       +--------------+
|           |                                       
|           |                       +--------------+
|           |                       |              |
|           | +--------(E)--------> | Restricted   |
|           |                       | Channel      |
|           | <--------(F)--------+ |              |
|           |                       |              |
|           |                       +--------------+
|           |                                       
|           |                       +--------------+
|           |                       |              |
|           | +--------(G)--------> | Root Channel |
|           |                       |              |
|           | <--------(H1)-------+ |              |
|           |                       |              |
|           | <--------(H2)-------+ |              |
+-----------+                       +--------------+
```

- A) The endpoint connects to Root channel and declares its role
- B1) Access granted. Server issues an access token along with other permission information. Additional information/user interactions can be used to authenticate the endpoint.
- B2) Access denied.
- C) The endpoint tries to connect to an allowed channel with access token.
- D1) Access granted. The server validates the access token and permission.
- D2) Access denied. Token expired.
- E) The endpoint tries to connect to an restricted channel with access token.
- F) Access denied. Invalid token.
- G) The endpoint tries to refresh access token.
- H1) Access granted. Server issues a new access token.
- H2) Access denied.

### Permissions
The allowed endpoint roles and their permissions are listed as follows:

Role     | Allowed namespace      | Note
-------- | ---------------------- | ----------------------------------------------------------
`atom`   | Server, Log, RPC, Atom | Only endpoints from `localhost` can declare as type `atom`
`device` | Log, RPC, Device       |

### Action: Declare an endpoint

```coffee
CONNECT /
EMIT    'register', id: ID, cb: PERMISSION_CB
```

#### `ID`

Field  | Type     | Description
------ | -------- | -----------------------------------------
`role` | `string` | Role of the endpoint. `atom` or `device`.

#### `PERMISSION_CB(err: string, permission: Permission): function<void>`
##### `err: string`

Value               | Description
------------------- | -------------------------------------------------
`null`              | Register succeeded
`"UNKNOWN_EP_ROLE"` | Declared role is not valid
`"LOCALHOST_ONLY"`  | Role can only be declared from localhost endpoint
`"ACCESS_DENIED"`   | Access denied (additional authentication failed)

##### `Permission`

Field     | Type            | Description
--------- | --------------- | ------------------
`token`   | `string`        | Access token
`refresh` | `string`        | Refresh token
`allowed` | `Array<string>` | Allowed namespaces

### Action: Refresh token

```coffee
CONNECT /
EMIT    'refresh', tokens: Tokens, cb: REFRESH_CB
```

#### `Tokens`

Field     | Type     | Description
--------- | -------- | ----------------
`token`   | `string` | Old access token
`refresh` | `string` | Refresh token

#### `REFRESH_CB(err: string, permission: Permission): function<void>`
##### `err: string`

Value             | Description
----------------- | --------------------
`null`            | Refresh succeeded
`"INVALID_TOKEN"` | Tokens are not valid

### Action: List connected endpoints

```coffee
CONNECT /
EMIT    'list', cb: LIST_CB
```

#### `LIST_CB(err, string, endpoints: Array<EndPoint>): function<void>`
##### `err: string`

Value  | Description
------ | -----------------
`null` | Refresh succeeded

##### `EndPoint`

Field    | Type     | Description
-------- | -------- | -----------------------------------------
`role`   | `string` | Role of the endpoint
`rootId` | `string` | Socket id of the endpoint on root channel
`rpcId`  | `string` | Socket id of the endpoint on rpc channel

### Event: `endpoint_connect`
Fired when a new endpoint is connected.

```coffee
ON 'endpoint_conect', endpoint: Endpoint
```

### Event: `endpoint_update`
Fired when an endpoint is updated (i.e. socket id changed)

```coffee
ON 'endpoint_update', endpoint: EndPoint
```

### Event: `endpoint_disconnect`
Fired when an endpoint is disconnected.

```coffee
ON 'endpoint_disconect', endpoint: EndPoint
```

### Action: Connect to a channel

```coffee
CONNECT /ns?token=access_token
```

#### Event: `error`

```coffee
ON 'error', error: Error
```

##### `error`

Message            | Description
------------------ | ----------------------------------------------------
`"NO_TOKEN"`       | No access token
`"INVALID_TOKEN"`  | Invalid access token
`"LOCALHOST_ONLY"` | Channel can only be accessed from localhost endpoint
`"ACCESS_DENIED"`  | Access token has no access to the channel
`"TOKEN_EXPIRED"`  | Access token has expired

## Logging
All authenticated endpoints can send and receive log messages via `/log` channel.

```coffee
CONNECT /log
```

### Action: Write a log entry

```coffee
EMIT 'log', type: LogTypeEnum, args: Array
```

#### `LogTypeEnum: enum<string>`

```coffee
TypeEnum = 'debug' | 'info' | 'log' | 'warn' | 'error'
```

### Event: 'log'
Fired when a log entry is received.

```coffee
ON 'log', entry: LogEntry
```

#### `LogEntry`

Field    | Type            | Description
-------- | --------------- | -----------------------------------
`source` | `string`        | Source ID of the log entry
`type`   | `LogTypeEnum`   | Log type
`t`      | `UInt32`        | Time stamp. (from `date.getTime()`)
`args`   | `Array<object>` | Log messages

### Event: `history`
Fired when a socket is connected, with all history log entries up-to a pre-configured count.

```coffee
ON 'history', entries: Array<LogEntry>
```

## RPC
An endpoint can hold references to other remote endpoints and invoke their methods via remote procedure calls. It can expose some methods for others to call in the mean time.

All RPC logic like remote module/method discovery and the actual calls are implemented as IO operations on the `/rpc` channel.

```coffee
CONNECT /rpc
```

All actions should be performed on one endpoints identified by its socket id.

```coffee
TO target_id: string
```

To simplify things, all modules should be singletons (that is, having exactly one instance per endpoint). This constraint eliminates the needs for remote object instantiation protocol.

### Action: List modules

```coffee
EMIT 'list_modules', cb: MODULE_CB
```

#### `MODULE_CB(err: string, modules: Array<string>): function<void>`
##### `err: string`

Value  | Description
------ | -----------------
`null` | Refresh succeeded

##### `modules: Array<string>`
A list of names of exported modules on the remote endpoint.

### Action: Require module

```coffee
EMIT 'require', moduleName: string, cb: REQUIRE_CB
```

#### `REQUIRE_CB(err: string, methods: Array<string>): function<void>`
##### `err: string`

Value         | Description
------------- | ---------------------------------------------------------
`null`        | Refresh succeeded
`"NO_MODULE"` | Module `moduleName` does not exist on the remote endpoint

##### `methods: Array<string>`
A list of names of the remote module's methods.

### Action: Call method

```coffee
EMIT 'call', moduleName: string, methodName: string, args: Array<object>, cb: RPC_CB
```

#### `RPC_CB(err: string, result: object): function<void>`
##### `err: string`

Value         | Description
------------- | ---------------------------------------------------------
`null`        | Refresh succeeded
`"NO_MODULE"` | Module `moduleName` does not exist on the remote endpoint
`"NO_METHOD"` | Method `methodName` does not exist on the remote module
`*`           | Any other error thrown by remote method

##### `result: object`
The return value of remote method.
