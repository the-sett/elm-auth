**Contacts for Support**
- @rupertlssmith on https://elmlang.slack.com
- @rupert on https://discourse.elm-lang.org

# elm-auth

This is an API specification for authentication of Elm apps.

The idea here is to capture the interaction with a typical authentication API as
an Elm package and to present that as a simpler API that applications need
authentication can make use of. The core of the API is the authentication commands, which are:

```
login : Credentials -> Cmd msg
refresh : Cmd msg
logout : Cmd msg
unauthed : Cmd msg
```

The commands yield messages that must be given to an `update` function which has
this signature and related types:

```
type Status chal
    = Failed
    | Challenged chal
    | LoggedOut
    | LoggedIn
        { scopes : List String
        , subject : String
        }

update : msg -> model -> ( model, Cmd msg, Maybe (Status chal))
```

That is, each message will update the internal model, and may produce a change
to the current authentication status.

# more things an API needs to do

* Add auth info to an HTTP header.

addAuthInfo : { a | headers : List Header } -> { a | headers : List Header }

* Answer challenges. 'chal' can be Never.

* Sign up new users.
* Verification links.

Are these part of a separate API?

* Fetch a user profile.
