module AuthAPI exposing (AuthAPI, Credentials, Status(..))

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

@docs AuthAPI, Credentials, Status

-}


{-| Username and password credentials.
-}
type alias Credentials =
    { username : String
    , password : String
    }


{-| The visible status of the authentication model.
-}
type Status chal
    = LoggedOut
    | LoggedIn { scopes : List String, subject : String }
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
type alias AuthAPI config model msg chal ext =
    { ext
        | init : config -> Result String model
        , login : Credentials -> Cmd msg
        , logout : Cmd msg
        , unauthed : Cmd msg
        , refresh : Cmd msg
        , update : msg -> model -> ( model, Cmd msg, Maybe (Status chal) )
    }
