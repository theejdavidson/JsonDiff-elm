module Main exposing (..)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Element.Input as Input
import Html
import Http exposing (Body, jsonBody)
import Json.Decode exposing (Decoder, decodeString, errorToString, fail, field, list, map2, map3, map4, string, value)
import Json.Encode exposing (Value, encode, object)



---- MODEL ----


type alias Model =
    { jsonTextA : String
    , jsonTextB : String
    , diff : Maybe DiffType
    , rbDiffType : RbDiffType
    , spellCheck : Bool
    , invalidJsonAError : Maybe String
    , invalidJsonBError : Maybe String
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
      , spellCheck = False
      , invalidJsonAError = Nothing
      , invalidJsonBError = Nothing
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
    | Spellcheck Bool
    | JsonErrorA (Maybe String)
    | JsonErrorB (Maybe String)


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


validateJson : String -> Model -> Maybe String
validateJson jsonText model =
    case decodeString value jsonText of
        Ok validJson ->
            Nothing

        Err err ->
            Just (errorToString err)


matchedPairDecoder : Decoder MatchedPair
matchedPairDecoder =
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
            Json.Decode.fail <| "Unknown type: " ++ typeText


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

        Spellcheck spellCheck ->
            ( { model | spellCheck = spellCheck }, Cmd.none )

        JsonErrorA maybeError ->
            case maybeError of
                Just invalidJsonAError ->
                    ( { model | invalidJsonAError = Just invalidJsonAError }, Cmd.none )

                Nothing ->
                    ( { model | invalidJsonAError = Nothing }, Cmd.none )

        JsonErrorB maybeError ->
            case maybeError of
                Just invalidJsonBError ->
                    ( { model | invalidJsonBError = Just invalidJsonBError }, Cmd.none )

                Nothing ->
                    ( { model | invalidJsonBError = Nothing }, Cmd.none )

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
                    ( { model | diff = Nothing }, Cmd.none )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "JsonDiff"
    , body =
        [ layout [] <|
            column [width fill]
                [ header model
                , column [ centerX, alignTop, padding 30 ]
                    [ jsonInput model
                    , Input.checkbox []
                        { onChange = Spellcheck
                        , icon = Input.defaultCheckbox
                        , checked = model.spellCheck
                        , label = Input.labelRight [] (text "Spellcheck")
                        }
                    , methodSelection model
                    , jsonOutput model
                    ]
                ]
        ]
    }


header : Model -> Element Msg
header model =
    row [ alignTop, width fill, padding 10, spacing 10 ]
        [ el [ alignLeft, Font.justify ] (text "Json Diff Tool\nwritten by Ethan Davidson")
        , newTabLink [ alignRight ] { url = "https://github.com/theejdavidson", label = image [] { src = "/images/GitHub-Mark-32px.png", description = "github logo" } }
        , newTabLink [] { url = "https://www.linkedin.com/in/ethan-davidson-67b786176/", label = image [] { src = "/images/LI-In-Bug.png", description = "linkedin logo" } }
        ]


jsonInput : Model -> Element Msg
jsonInput model =
    row
        [ centerX
        ]
        [ jsonTextElementA model model.jsonTextA
        , jsonTextElementB model model.jsonTextB
        ]


methodSelection : Model -> Element Msg
methodSelection model =
    column
        [ centerX, spacingXY 5 10 ]
        [ Input.radioRow
            [ spacing 55 ]
            { onChange = \rbDiffType -> RbSelected rbDiffType
            , selected = Just model.rbDiffType
            , label = Input.labelHidden "Diff method"
            , options =
                [ Input.option RbSortedKey (text "Sorted Key")
                , Input.option RbConsolidated (text "Consolidated")
                ]
            }
        , Input.button [ centerX, Background.color lightBlue, spacingXY 10 20, paddingXY 30 5, Border.width 3, Border.rounded 6, centerY ]
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


consolidatedValueCell consolidatedRow =
    case consolidatedRow.row_type of
        ConsolidatedMatchedPair ->
            row [ Border.width 1, Border.color standardBorderColor, Background.color matchingContentColor ]
                [ Element.el [ alignLeft ] (text "= ")
                , Element.el [ alignLeft ] (text (valueToString consolidatedRow.value))
                ]

        Mismatched ->
            row [ Border.width 1, Border.color standardBorderColor, Background.color mismatchedContentColor ]
                [ Element.el [ alignLeft ] (text "≠ ")
                , Element.el [ alignLeft ] (text (valueToString consolidatedRow.value))
                , Element.el [ centerX ]
                    (text
                        (case consolidatedRow.other_value of
                            Just value ->
                                valueToString value

                            Nothing ->
                                "null"
                        )
                    )
                ]

        MissingFromA ->
            row [ Border.width 1, Background.color missingFromAColor ]
                [ Element.el [ alignLeft ] (text "⇠ ")
                , Element.el [ alignLeft ] (text (valueToString consolidatedRow.value))
                ]

        MissingFromB ->
            row [ Border.width 1, Background.color missingFromBColor ]
                [ Element.el [ alignLeft ] (text "⇢ ")
                , Element.el [ alignLeft ] (text (valueToString consolidatedRow.value))
                ]


consolidatedListElement : List ConsolidatedRow -> Element Msg
consolidatedListElement consolidated =
    Element.table [ paddingXY 30 30 ]
        { data = consolidated
        , columns =
            [ { header = el [ Font.bold ] (Element.text "Key")
              , width = fill
              , view = \con -> el [ Font.alignLeft, Border.width 1, Border.color standardBorderColor ] (Element.text con.key)
              }
            , { header = el [ Font.bold ] (Element.text "Value")
              , width = fill
              , view = consolidatedValueCell
              }
            ]
        }


sortedKeyDiffElement : SortedKeyDiff -> Element Msg
sortedKeyDiffElement sortedKeyDiff =
    Element.column
        [ centerX, spacingXY 4 10, padding 15 ]
        [ el [ centerX, Font.bold ] (Element.text "Mismatched Content")
        , mismatchedContent sortedKeyDiff.mismatched_value
        , row []
            [ column [ alignLeft, alignTop ]
                [ el [ centerX, Font.bold ] (Element.text "Missing from A")
                , el [ Background.color missingFromAColor ] (matchingContent sortedKeyDiff.missing_from_a)
                ]
            , column [ alignRight, alignTop ]
                [ el [ centerX, Font.bold ] (Element.text "Missing from B")
                , el [ Background.color missingFromBColor ] (matchingContent sortedKeyDiff.missing_from_b)
                ]
            ]
        , el [ centerX, Font.bold ] (Element.text "Matching Key/Value Pairs")
        , el [ Background.color matchingContentColor, centerX, width fill ] (matchingContent sortedKeyDiff.matched_pairs)
        ]


matchingContent : List MatchedPair -> Element Msg
matchingContent listOfMatchedValues =
    Element.table []
        { data = listOfMatchedValues
        , columns =
            [ { header = el [ Border.width 1, Border.color standardBorderColor, Font.bold ] (Element.text "Key")
              , width = fill
              , view = \matchedValue -> el [ Border.width 1, Border.color standardBorderColor, Font.alignLeft ] (Element.text matchedValue.key)
              }
            , { header = el [ Border.width 1, Border.color standardBorderColor, Font.bold ] (Element.text "Value")
              , width = fill
              , view = \matchedValue -> el [ Border.width 1, Border.color standardBorderColor, Font.alignLeft ] (Element.text (Json.Encode.encode 0 matchedValue.value))
              }
            ]
        }


mismatchedContent : List MismatchedValue -> Element Msg
mismatchedContent listOfMismatchedValues =
    Element.table [ Background.color mismatchedContentColor ]
        { data = listOfMismatchedValues
        , columns =
            [ { header = el [ Border.width 1, Border.color standardBorderColor, Font.bold ] (Element.text "Key")
              , width = fill
              , view = \mismatchedValue -> el [ Border.width 1, Border.color standardBorderColor, Font.alignLeft ] (Element.text mismatchedValue.key)
              }
            , { header = el [ Border.width 1, Border.color standardBorderColor, Font.bold ] (Element.text "A Value")
              , width = fill
              , view = \mismatchedValue -> el [ Border.width 1, Border.color standardBorderColor, Font.alignLeft ] (Element.text (Json.Encode.encode 0 mismatchedValue.value_a))
              }
            , { header = el [ Border.width 1, Border.color standardBorderColor, Font.bold ] (Element.text "B Value")
              , width = fill
              , view = \mismatchedValue -> el [ Border.width 1, Border.color standardBorderColor, Font.alignLeft ] (Element.text (Json.Encode.encode 0 mismatchedValue.value_b))
              }
            ]
        }


jsonTextElementA : Model -> String -> Element Msg
jsonTextElementA model jsonTextA =
    column [ width fill, alignTop ]
        [ Input.multiline
            [ height (px 350)
            , Border.width 1
            , Border.rounded 3
            , Border.color standardBorderColor
            , padding 3
            , case validateJson jsonTextA model of
                Just errorText ->
                    Background.color lightRed

                Nothing ->
                    Background.color lightGreen
            ]
            { onChange = JsonTextA
            , text = jsonTextA
            , placeholder = Nothing
            , label =
                Input.labelAbove [] <|
                    Element.text "Paste JSON text A below:"
            , spellcheck = model.spellCheck
            }
        , paragraph []
            [ case validateJson jsonTextA model of
                Just stringError ->
                    text stringError

                Nothing ->
                    text ""
            ]
        ]


jsonTextElementB : Model -> String -> Element Msg
jsonTextElementB model jsonTextB =
    column [ width fill, alignTop ]
        [ Input.multiline
            [ height (px 350)
            , Border.width 1
            , Border.rounded 3
            , Border.color standardBorderColor
            , padding 3
            , case validateJson jsonTextB model of
                Just errorText ->
                    Background.color lightRed

                Nothing ->
                    Background.color lightGreen
            ]
            { onChange = JsonTextB
            , text = jsonTextB
            , placeholder = Nothing
            , label =
                Input.labelAbove [] <|
                    Element.text "Paste JSON text B below:"
            , spellcheck = model.spellCheck
            }
        , paragraph []
            [ case validateJson jsonTextB model of
                Just stringError ->
                    text stringError

                Nothing ->
                    text ""
            ]
        ]



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
    rgb255 92 213 255


lightYellow =
    rgb255 255 255 200


white =
    rgb255 255 255 255


forestGreen =
    rgb255 34 139 34


purple =
    rgb255 128 0 128


lightRed =
    rgb255 255 200 200


lightGreen =
    rgb255 200 255 200


mismatchedContentColor : Color
mismatchedContentColor =
    lightYellow


matchingContentColor : Color
matchingContentColor =
    lightBlue


missingFromAColor : Color
missingFromAColor =
    lightRed


missingFromBColor : Color
missingFromBColor =
    lightGreen


standardBorderColor : Color
standardBorderColor =
    lightCharcoal
