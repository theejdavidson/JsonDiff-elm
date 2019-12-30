module Main exposing (..)

--import Html as HTML exposing (Html, button, div, h1, img, text)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes exposing (src)
import Http
import Json.Decode exposing (Decoder, field, list, map2, string, value)
import Json.Encode exposing (Value)



---- MODEL ----


type alias Model =
    { jsonTextA : String
    , jsonTextB : String
    , jsonDiff : String
    }


type alias Flags =
    ()


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { jsonTextA = "<Paste first JSON text here>"
      , jsonTextB = "<Paste second JSON text here>"
      , jsonDiff = "Json Diff"
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


type Msg
    = NoOp
    | JsonTextA String
    | JsonTextB String
    | JsonDiff String
    | UserRequestedDiff --(Result Http.Error ())
    | ServerReturnedDiff (Result Http.Error SortedKeyDiff)


type alias MatchedPair =
    { key : String
    , value : Value
    }


type alias SortedKeyDiff =
    { matched_pairs : List MatchedPair }


type alias MissingValue =
    { key : String
    , value : String
    }


matchedPairDecoder : Decoder MatchedPair
matchedPairDecoder =
    let
        _ =
           -- Debug.log "Simple value:" (Json.Encode.int 3)
            Debug.log "2 == 3?" (areEqual (Json.Encode.int 3) (Json.Encode.int 3)) 
    in
    map2
        MatchedPair
        (field "key" string)
        (field "value" value)


sortedKeyDiffDecoder : Decoder SortedKeyDiff
sortedKeyDiffDecoder =
    Json.Decode.map
        SortedKeyDiff
        (field "matched_pairs" (list matchedPairDecoder))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsonTextA s ->
            ( { model | jsonTextA = s }, Cmd.none )

        JsonTextB s ->
            ( { model | jsonTextB = s }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        JsonDiff s ->
            ( { model | jsonDiff = s }, Cmd.none )

        UserRequestedDiff ->
            ( { model | jsonDiff = "This will come from the server" }
            , Http.get
                { url = "http://localhost:4000/sorted-key-diff"
                , expect = Http.expectJson ServerReturnedDiff sortedKeyDiffDecoder
                }
            )

        ServerReturnedDiff result ->
            case result of
                Ok fullText ->
                    ( { model | jsonDiff = Debug.toString fullText }, Cmd.none )

                Err error ->
                    let
                        _ =
                            Debug.log "Error is" error
                    in
                    ( { model | jsonDiff = "got error" }, Cmd.none )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "JsonDiff"
    , body =
        [ layout [] <|
            column [ width fill, spacingXY 0 20 ]
                [ jsonInput model
                ]
        ]
    }


jsonInput : Model -> Element Msg
jsonInput model =
    column
        [ width (px 600)
        , spacingXY 0 10
        , centerX
        ]
        [ jsonTextElementA model.jsonTextA
        , jsonTextElementB model.jsonTextB
        , Input.button [ centerX, Background.color (Element.rgb255 238 238 238) ]
            { onPress = Just UserRequestedDiff
            , label = Element.text "Diff"
            }
        , jsonDiffElement model.jsonDiff
        ]


jsonDiffElement : String -> Element Msg
jsonDiffElement jsonDiff =
    Element.paragraph
        [ height (px 300)
        , Border.width 1
        , Border.rounded 3
        , Border.color lightCharcoal
        , padding 3
        ]
        [ text jsonDiff --Need to make this a variable call
        ]


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
