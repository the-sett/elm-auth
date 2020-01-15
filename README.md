**Contacts for Support**
- @rupertlssmith on https://elmlang.slack.com
- @rupert on https://discourse.elm-lang.org

# elm-auth

This is an API specification for authentication of Elm apps.

The idea here is to capture the interaction with a typical authentication API as
an Elm package and to present that as a simpler API which applications needing
authentication can make use of. The core of the API is the authentication commands, which are:

```
login : Credentials -> Cmd msg
refresh : Cmd msg
logout : Cmd msg
unauthed : Cmd msg
```

The purpose of these commands are:

* **login** - Supply a username and password as login credentials and attempt to authenticate.
* **refresh** - Attempt to refresh the authentication. Most authentication relies on tokens which expire after some time.
* **logout** - Issue an explicit logout command, telling the back-end that this is
happening if it supports that.
* **unauthed** - Resets the auth state to `LoggedOut` but without issuing an explicit
logout command. This is usually used when some API returns a 401 or 403 response
indicating that unauthorised access has been attempted.

The commands yield messages that must be given to an `update` function which has
this signature and related types:

```
update : msg -> model -> ( model, Cmd msg, Maybe (Status chal))

type Status chal
    = Failed
    | Challenged chal
    | LoggedOut
    | LoggedIn
        { scopes : List String
        , subject : String
        }
```

That is, each message will update the internal model, and may produce a change
to the current authentication status.

# An extensible API with multiple implementations.

This package contains an API specification and some related utility code. The actual auth implementations that interact with various back-ends are:


[the-sett/elm-auth-aws](https://github.com/the-sett/elm-auth-aws) - Authenticate against AWS Cognito.

[the-sett/elm-auth-the-sett](https://github.com/the-sett/elm-auth-the-sett) - Authenticate against a custom auth server.

The API is presented as an extensible record of functions:

```
type alias AuthAPI config model msg chal ext =
    { ext
        | init : config -> Result String model
        , login : Credentials -> Cmd msg
        , logout : Cmd msg
        , unauthed : Cmd msg
        , refresh : Cmd msg
        , update : msg -> model -> ( model, Cmd msg, Maybe (Status chal) )
        , addAuthHeaders : model -> List Http.Header -> List Http.Header

    }
```

Each implementation fills in its own types for `config`, `model`, `msg`, `chal` and `ext`. The `model` and `msg` types for an implementation are likely to be opaque to hide the internal workings.

The `chal` type will be `Never` if the authentication API does not issue additional challenges, or some description of the possible extra challenges
that may need to be answered in order to authenticate - for 2-factor authentication for example.

Once authentication has been completed, further calls to some API often require
that a 'bearer' token be added to HTTP headers to prove the callers granted authority to use that API obtained through the authentication. The `addAuthHeaders` function can ammend a list of HTTP headers on a request to include the necessary additions.
