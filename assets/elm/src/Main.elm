module Main exposing (..)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Http exposing (Body, jsonBody)
import Json.Decode exposing (Decoder, fail, field, list, map2, map3, map4, string, value)
import Json.Encode exposing (Value, encode, object)



---- MODEL ----


type alias Model =
    { jsonTextA : String
    , jsonTextB : String
    , diff : Maybe DiffType
    , rbDiffType : RbDiffType
    }


type alias Flags =
    ()


type DiffType
    = SortedKey SortedKeyDiff
    | Consolidated (List ConsolidatedRow)


type
    RbDiffType
    --mutually exclusive list for radio button
    = RbSortedKey
    | RbConsolidated


type alias ConsolidatedRow =
    { key : String
    , row_type : ConsolidatedType
    , value : Value
    , other_value : Maybe Value
    }


type ConsolidatedType
    = ConsolidatedMatchedPair
    | Mismatched
    | MissingFromA
    | MissingFromB


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
      , diff = Nothing
      , rbDiffType = RbSortedKey
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
    | ServerReturnedDiff (Result Http.Error DiffType)
    | RbSelected RbDiffType


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


sortedKeyDiffDecoder : Decoder DiffType
sortedKeyDiffDecoder =
    Json.Decode.map SortedKey
        (map4
            SortedKeyDiff
            (field "matched_pairs" (list matchedPairDecoder))
            (field "mismatched_values" (list mismatchedValueDecoder))
            (field "missing_from_a" (list matchedPairDecoder))
            (field "missing_from_b" (list matchedPairDecoder))
        )


consolidatedRowDecoder : Decoder ConsolidatedRow
consolidatedRowDecoder =
    map4
        ConsolidatedRow
        (field "key" string)
        (field "row_type" string |> Json.Decode.andThen consolidatedTypeDecoder)
        (field "value" value)
        (field "other_value" (Json.Decode.maybe value))


consolidatedTypeDecoder typeText =
    case typeText of
        "matched_pair" ->
            Json.Decode.succeed ConsolidatedMatchedPair

        "mismatched" ->
            Json.Decode.succeed Mismatched

        "missing_from_a" ->
            Json.Decode.succeed MissingFromA

        "missing_from_b" ->
            Json.Decode.succeed MissingFromB

        _ ->
            Json.Decode.fail <| "Unknown theme: " ++ typeText


consolidatedDiffDecoder : Decoder DiffType
consolidatedDiffDecoder =
    Json.Decode.map Consolidated
        (list consolidatedRowDecoder)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsonTextA s ->
            ( { model | jsonTextA = s }, Cmd.none )

        JsonTextB s ->
            ( { model | jsonTextB = s }, Cmd.none )

        RbSelected rbDiffType ->
            ( { model | rbDiffType = rbDiffType }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        UserRequestedDiff ->
            case model.rbDiffType of
                RbSortedKey ->
                    ( model
                    , Http.post
                        { url = "http://localhost:4000/api/sorted-key-diff"
                        , body = encodeBody model.jsonTextA model.jsonTextB
                        , expect = Http.expectJson ServerReturnedDiff sortedKeyDiffDecoder
                        }
                    )

                RbConsolidated ->
                    ( model
                    , Http.post
                        { url = "http://localhost:4000/api/consolidated-diff"
                        , body = encodeBody model.jsonTextA model.jsonTextB
                        , expect = Http.expectJson ServerReturnedDiff consolidatedDiffDecoder
                        }
                    )

        ServerReturnedDiff maybeDiff ->
            case maybeDiff of
                Ok diff ->
                    ( { model | diff = Just diff }, Cmd.none )

                Err error ->
                    let
                        _ =
                            Debug.log "Error is" error
                    in
                    ( { model | diff = Nothing }, Cmd.none )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "JsonDiff"
    , body =
        [ layout [] <|
            column []
                [ jsonInput model
                , methodSelection model
                , jsonOutput model
                ]
        ]
    }


jsonInput : Model -> Element Msg
jsonInput model =
    row
        [ width fill
        , padding 20
        , spacing 20
        , centerX
        ]
        [ jsonTextElementA model.jsonTextA
        , jsonTextElementB model.jsonTextB
        ]


methodSelection : Model -> Element Msg
methodSelection model =
    column
        [ centerX ]
        [ Input.radioRow
            [ spacing 3]
            { onChange = \rbDiffType -> RbSelected rbDiffType
            , selected = Just model.rbDiffType
            , label = Input.labelHidden "Diff method"
            , options =
                [ Input.option RbSortedKey (text "Sorted Key")
                , Input.option RbConsolidated (text "Consolidated")
                ]
            }
        , Input.button [ centerX, Background.color lightBlue, spacing 10 ]
            { onPress = Just UserRequestedDiff
            , label = Element.text "Diff"
            }
        ]


jsonOutput : Model -> Element Msg
jsonOutput model =
    case model.diff of
        Just diff ->
            case diff of
                SortedKey sortedKeyDiff ->
                    sortedKeyDiffElement sortedKeyDiff

                Consolidated consolidatedList ->
                    consolidatedListElement consolidatedList

        Nothing ->
            text ""



--consolidatedRowElement : ConsolidatedRow -> Element Msg
--consolidatedRowElement consolidatedRow =
--  case consolidatedRow.other_value of
-- Just other_value ->


consolidatedListElement : List ConsolidatedRow -> Element Msg
consolidatedListElement consolidated =
    Element.el [] (Element.text "")


sortedKeyDiffElement : SortedKeyDiff -> Element Msg
sortedKeyDiffElement sortedKeyDiff =
    Element.column
        [ centerX ]
        [ el [ centerX ] (Element.text "Mismatched Content")
        , mismatchedContent sortedKeyDiff.mismatched_value
        , el [ centerX ] (Element.text "Missing from A")
        , matchingContent sortedKeyDiff.missing_from_a
        , Element.text "Missing from B"
        , matchingContent sortedKeyDiff.missing_from_b
        , el [ centerX ] (Element.text "Matching Key/Value Pairs")
        , matchingContent sortedKeyDiff.matched_pairs
        ]


matchingContent : List MatchedPair -> Element Msg
matchingContent listOfMatchedValues =
    Element.table []
        { data = listOfMatchedValues
        , columns =
            [ { header = el [Font.bold] (Element.text "Key")
              , width = fill
              , view = \matchedValue -> el [Font.alignLeft](Element.text matchedValue.key)
              }
            , { header = el [Font.bold] (Element.text "Value")
              , width = fill
              , view = \matchedValue -> el [Font.alignLeft] (Element.text (Json.Encode.encode 0 matchedValue.value))
              }
            ]
        }


mismatchedContent : List MismatchedValue -> Element Msg
mismatchedContent listOfMismatchedValues =
    Element.table [ Background.color lightYellow ]
        { data = listOfMismatchedValues
        , columns =
            [ { header = el [ Font.bold, Background.color lightBlue ] (Element.text "Key")
              , width = fill
              , view = \mismatchedValue -> el [ Font.alignLeft ] (Element.text mismatchedValue.key)
              }
            , { header = el [ Font.bold ] (Element.text "A Value")
              , width = fill
              , view = \mismatchedValue -> el [ Font.alignLeft ] (Element.text (Json.Encode.encode 0 mismatchedValue.value_a))
              }
            , { header = el [ Font.bold ] (Element.text "B Value")
              , width = fill
              , view = \mismatchedValue -> el [ Font.alignLeft ] (Element.text (Json.Encode.encode 0 mismatchedValue.value_b))
              }
            ]
        }


jsonTextElementA : String -> Element Msg
jsonTextElementA jsonTextA =
    Input.multiline
        [ height (px 600)
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
                Element.text "Paste JSON text A below:"
        , spellcheck = False
        }


jsonTextElementB : String -> Element Msg
jsonTextElementB jsonTextB =
    Input.multiline
        [ height (px 600)
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
                Element.text "Paste JSON text B below:"
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


blue =
    rgb255 52 101 164


lightBlue =
    rgb255 139 178 248


lightYellow =
    rgb255 255 255 96


white =
    rgb255 255 255 255
