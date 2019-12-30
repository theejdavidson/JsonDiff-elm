module Main exposing (..)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes exposing (src)
import Http exposing (Body, jsonBody)
import Json.Decode exposing (Decoder, field, list, map2, map3, map4, string, value)
import Json.Encode exposing (Value, encode, object)



---- MODEL ----


type alias Model =
    { jsonTextA : String
    , jsonTextB : String
    , sortedKeyDiff : Maybe SortedKeyDiff
    }


type alias Flags =
    ()


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { jsonTextA = """{
    "street_address": "1232 Martin Luthor King Dr",
    "zip": 60323,
    "city": "Smallville",
    "country": "USA"
}"""
      , jsonTextB = """{
    "street_address":
    { "name" : "Martin Luthor King Dr", "number" : 1323 },
    "apt" : 40,
    "zip": 60323,
    "city": "Bigville"
}"""
      , sortedKeyDiff = Nothing
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



---- UPDATE ----


areEqual : Value -> Value -> Bool
areEqual a b =
    a == b


valueToString : Value -> String
valueToString value =
    Json.Encode.encode 0 value


type Msg
    = NoOp
    | JsonTextA String
    | JsonTextB String
    | UserRequestedDiff
    | ServerReturnedDiff (Result Http.Error SortedKeyDiff)


type alias MatchedPair =
    { key : String
    , value : Value
    }


type alias MismatchedValue =
    { key : String
    , value_a : Value
    , value_b : Value
    }


type alias SortedKeyDiff =
    { matched_pairs : List MatchedPair
    , mismatched_value : List MismatchedValue --keys match but values are mismatched
    , missing_from_a : List MatchedPair
    , missing_from_b : List MatchedPair
    }


aMatchedPair =
    { key = "Foo"
    , value = ""
    }


getMatchedPairs sortedDiffKey =
    sortedDiffKey.matched_pairs



--sortedKeyDiffSample = { ["key1" : 1, "key2" : 2]}


encodeBody : String -> String -> Body
encodeBody jsonTextA jsonTextB =
    jsonBody
        (object
            [ ( "jsonTextA", Json.Encode.string jsonTextA )
            , ( "jsonTextB", Json.Encode.string jsonTextB )
            ]
        )


matchedPairDecoder : Decoder MatchedPair
matchedPairDecoder =
    let
        _ =
            Debug.log "Simple value:" (valueToString (Json.Encode.int 3))

        -- Debug.log "2 == 3?" (areEqual (Json.Encode.int 3) (Json.Encode.int 3))
    in
    map2
        MatchedPair
        (field "key" string)
        (field "value" value)


mismatchedValueDecoder : Decoder MismatchedValue
mismatchedValueDecoder =
    map3
        MismatchedValue
        (field "key" string)
        (field "value_a" value)
        (field "value_b" value)


sortedKeyDiffDecoder : Decoder SortedKeyDiff
sortedKeyDiffDecoder =
    map4
        SortedKeyDiff
        (field "matched_pairs" (list matchedPairDecoder))
        (field "mismatched_values" (list mismatchedValueDecoder))
        (field "missing_from_a" (list matchedPairDecoder))
        (field "missing_from_b" (list matchedPairDecoder))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsonTextA s ->
            ( { model | jsonTextA = s }, Cmd.none )

        JsonTextB s ->
            ( { model | jsonTextB = s }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        UserRequestedDiff ->
            ( model
            , Http.post
                { url = "http://localhost:4000/api/sorted-key-diff"
                , body = encodeBody model.jsonTextA model.jsonTextB
                , expect = Http.expectJson ServerReturnedDiff sortedKeyDiffDecoder
                }
            )

        ServerReturnedDiff result ->
            case result of
                Ok sortedKeyDiff ->
                    ( { model | sortedKeyDiff = Just sortedKeyDiff }, Cmd.none )

                Err error ->
                    let
                        _ =
                            Debug.log "Error is" error
                    in
                    ( { model | sortedKeyDiff = Nothing }, Cmd.none )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "JsonDiff"
    , body =
        [ layout [] <|
            column [ width fill, spacingXY 50 20 ]
                [ jsonInput model
                ]
        ]
    }


jsonInput : Model -> Element Msg
jsonInput model =
    column
        [ width fill
        , padding 20
        , spacingXY 10 10
        , centerX
        ]
        [ jsonTextElementA model.jsonTextA
        , jsonTextElementB model.jsonTextB
        , Input.button [ centerX, Background.color (Element.rgb255 238 238 238) ]
            { onPress = Just UserRequestedDiff
            , label = Element.text "Diff"
            }
        , case model.sortedKeyDiff of
            Just sortedKeyDiff ->
                jsonDiffElement sortedKeyDiff

            Nothing ->
                text "No content yet"
        ]


jsonDiffElement : SortedKeyDiff -> Element Msg
jsonDiffElement sortedKeyDiff =
    Element.column
        []
        [ Element.html (Html.h3 [] [ Html.text "Mismatched Content" ])
        , mismatchedContent sortedKeyDiff.mismatched_value
        , Element.html (Html.h3 [] [ Html.text "Missing from A" ])
        , matchingContent sortedKeyDiff.missing_from_a
        , Element.html (Html.h3 [] [ Html.text "Missing from B" ])
        , matchingContent sortedKeyDiff.missing_from_b
        , Element.html (Html.h3 [] [ Html.text "Matching Key/Value Pairs" ])
        , matchingContent sortedKeyDiff.matched_pairs
        ]


matchingContent listOfMatchedValues =
    Element.html
        (Html.table []
            [ Html.tbody [ Html.Attributes.style "width" "100%" ]
                (List.map matchingContentRow listOfMatchedValues)
            ]
        )


matchingContentRow matchedValue =
    Html.tr []
        [ Html.td
            [ Html.Attributes.style "background-color" "salmon"
            , Html.Attributes.style "width" "50%"
            ]
            [ Html.text matchedValue.key ]
        , Html.td
            [ Html.Attributes.style "background-color" "lightblue"
            , Html.Attributes.style "width" "30%"
            ]
            [ Html.text (Json.Encode.encode 0 matchedValue.value) ]
        ]


mismatchedValueRow mismatchedValue =
    Html.tr []
        [ Html.td
            [ Html.Attributes.style "background-color" "salmon"
            , Html.Attributes.style "width" "50%"
            ]
            [ Html.text mismatchedValue.key ]
        , Html.td
            [ Html.Attributes.style "background-color" "lightblue"
            , Html.Attributes.style "width" "30%"
            ]
            [ Html.text (Json.Encode.encode 0 mismatchedValue.value_a) ]
        , Html.td
            [ Html.Attributes.style "background-color" "lightyellow"
            , Html.Attributes.style "width" "30%"
            ]
            [ Html.text (Json.Encode.encode 0 mismatchedValue.value_b) ]
        ]


mismatchedContent listOfMismatchedValues =
    Element.html
        (Html.table []
            [ Html.tbody [ Html.Attributes.style "width" "100%" ]
                (List.map mismatchedValueRow listOfMismatchedValues)
            ]
        )


jsonTextElementA : String -> Element Msg
jsonTextElementA jsonTextA =
    Input.multiline
        [ height (px 300)
        , Border.width 1
        , Border.rounded 3
        , Border.color lightCharcoal
        , padding 3
        ]
        { onChange = JsonTextA
        , text = jsonTextA
        , placeholder = Nothing
        , label =
            Input.labelAbove [] <|
                Element.text "Paste first json text below:"
        , spellcheck = False
        }


jsonTextElementB : String -> Element Msg
jsonTextElementB jsonTextB =
    Input.multiline
        [ height (px 300)
        , Border.width 1
        , Border.rounded 3
        , Border.color lightCharcoal
        , padding 3
        ]
        { onChange = JsonTextB
        , text = jsonTextB
        , placeholder = Nothing
        , label =
            Input.labelAbove [] <|
                Element.text "Paste second json text below:"
        , spellcheck = False
        }



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- Color attributes


lightCharcoal : Color
lightCharcoal =
    rgb255 136 138 133
