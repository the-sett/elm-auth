module AuthAPI exposing (AuthAPI, AuthInfo, Credentials, Status(..))

{-| AuthAPI defines an extensible API for interacting with authentication.
It provides the most common authentication commands that applications need, and
leaves room for implementations to extend the set of commands to cater for
variations in the behaviour of authentication services.

In particular the `Status` type defines a `Challenged` state which has a `chal`
type variable, but there are no commands for answering challenges. Some
implementations that do not have challenges will use the `Never` type for this,
and other implementations with support for things such as 2-factor authentication
will supply an appropriate challenge type and commands to answer challenges.


# The authentication API.

@docs AuthAPI, AuthInfo, Credentials, Status

-}

import Http


{-| Username and password credentials.
-}
type alias Credentials =
    { username : String
    , password : String
    }


{-| Defines properties that must be available once authenticated. This is
extensible so implementations can add extra information.

`subject` should provide some unique id for the authenticated user. This might
typically be used as the key to request the users profile.

`scopes` may contain strings that give some application specific indication of
what access rights the authenticated user has. This might typically be used to
only render parts of the UI that are going to be able to work correctly when a
user has certain permissions.

-}
type alias AuthInfo auth =
    { auth | scopes : List String, subject : String }


{-| The visible status of the authentication model.
-}
type Status auth chal
    = LoggedOut
    | LoggedIn (AuthInfo auth)
    | Failed
    | Challenged chal


{-| The extensible authentication API.

This is presented as functions in an extensible record. The reason for this
slightly unusual presentation is that it allows a type to be defined for the
whole API, with all the parts that are variable amongst implementations presented
as type variables.

This allows multiple implementations of this API to be written that all conform
to a common pattern. This standardizes how authentcation is handled in
applications.

-}
type alias AuthAPI config model msg auth chal ext =
    { ext
        | init : config -> Result String model
        , login : Credentials -> Cmd msg
        , logout : Cmd msg
        , unauthed : Cmd msg
        , refresh : Cmd msg
        , update : msg -> model -> ( model, Cmd msg, Maybe (Status auth chal) )
        , addAuthHeaders : model -> List Http.Header -> List Http.Header
    }
