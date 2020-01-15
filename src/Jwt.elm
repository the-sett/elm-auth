module Jwt exposing
    ( decode, isExpired
    , StandardToken
    , JwtError
    )

{-| Decoding of JWT tokens.

@docs decode, isExpired
@docs StandardToken
@docs JwtError

-}

import Base64
import Json.Decode as Decode exposing (Decoder, Value, field)
import Json.Decode.Extra exposing (andMap, withDefault)
import Time exposing (Posix)


{-| Describes the standard JWT token fields.

Note that the standard token does not have to be used, it is provided
here for convenience. All of the fields are `Maybe`s which is not very nice
when you know that some implementation can be relied on to provide certain
fields.

This module can work with any token definition; supply a decoder for the token
you want to use. A decoder for the standard token is provided in this module.

-}
type alias StandardToken =
    { sub : Maybe String
    , iss : Maybe String
    , aud : Maybe String
    , exp : Maybe Posix
    , nbf : Maybe Posix
    , iat : Maybe Posix
    , jti : Maybe String
    }


{-| A decoder for the standard token.
-}
standardTokenDecoder : Decoder StandardToken
standardTokenDecoder =
    Decode.succeed
        (\sub iss aud exp nbf iat jti ->
            { sub = sub
            , iss = iss
            , aud = aud
            , exp = exp
            , nbf = nbf
            , iat = iat
            , jti = jti
            }
        )
        |> andMap (Decode.maybe (Decode.field "sub" Decode.string))
        |> andMap (Decode.maybe (Decode.field "iss" Decode.string))
        |> andMap (Decode.maybe (Decode.field "aud" Decode.string))
        |> andMap
            (Decode.maybe
                (Decode.map
                    (Time.millisToPosix << (*) 1000)
                    (Decode.field "exp" Decode.int)
                )
            )
        |> andMap
            (Decode.maybe
                (Decode.map
                    (Time.millisToPosix << (*) 1000)
                    (Decode.field "nbf" Decode.int)
                )
            )
        |> andMap
            (Decode.maybe
                (Decode.map
                    (Time.millisToPosix << (*) 1000)
                    (Decode.field "iat" Decode.int)
                )
            )
        |> andMap (Decode.maybe (Decode.field "jti" Decode.string))


{-| Defines the possible errors that can be encountered when decoding a token.
-}
type JwtError
    = TokenExpired
    | TokenProcessingError String
    | TokenDecodeError String


{-| Decodes a JWT token from its encoded string format.
-}
decode : String -> Decoder token -> Result JwtError token
decode token decoder =
    extractAndDecodeToken decoder token


{-| Decodes just the "exp" field from a JWT token from its encoded string format
and compares for expiry with the supplied time stamp.

If the token does not contain an "exp" field, this function will always return
`True`. It is expected that the supplied token will contain this field.

-}
isExpired : Posix -> String -> Bool
isExpired now token =
    case extractAndDecodeToken (field "exp" Decode.int) token of
        Result.Ok exp ->
            Time.posixToMillis now > (exp * 1000)

        Result.Err _ ->
            True


extractAndDecodeToken : Decode.Decoder a -> String -> Result JwtError a
extractAndDecodeToken dec s =
    let
        f1 =
            String.split "." <| unurl s

        f2 =
            List.map fixlength f1
    in
    case f2 of
        _ :: (Result.Err e) :: _ :: [] ->
            Result.Err e

        _ :: (Result.Ok encBody) :: _ :: [] ->
            case Base64.decode encBody of
                Result.Ok body ->
                    case Decode.decodeString dec body of
                        Result.Ok x ->
                            Result.Ok x

                        Result.Err e ->
                            Result.Err (TokenDecodeError <| Decode.errorToString e)

                Result.Err e ->
                    Result.Err (TokenProcessingError e)

        _ ->
            Result.Err <| TokenProcessingError "Token has invalid shape"


unurl : String -> String
unurl =
    let
        fix ch =
            case ch of
                '-' ->
                    '+'

                '_' ->
                    '/'

                c ->
                    c
    in
    String.map fix


fixlength : String -> Result JwtError String
fixlength s =
    case modBy 4 (String.length s) of
        0 ->
            Result.Ok s

        2 ->
            Result.Ok <| String.concat [ s, "==" ]

        3 ->
            Result.Ok <| String.concat [ s, "=" ]

        _ ->
            Result.Err <| TokenProcessingError "Wrong length"
