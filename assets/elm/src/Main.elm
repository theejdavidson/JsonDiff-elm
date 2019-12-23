module Main exposing (..)

import Browser
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html as HTML exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)



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


type Msg
    = NoOp
    | JsonTextA String
    | JsonTextB String
    | JsonDiff String


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
        [ width (px 800)
        , spacingXY 0 10
        , centerX
        ]
        [ jsonTextElementA model.jsonTextA
        , jsonTextElementB model.jsonTextB
        , jsonDiffElement 
        ]


jsonDiffElement :  Element Msg
jsonDiffElement =
    Input.multiline
        [ height (px 300)
        , Border.width 1
        , Border.rounded 3
        , Border.color lightCharcoal
        , padding 3
        ]
        { onChange = JsonDiff
        , text = "Diff from sever"
        , placeholder = Nothing
        , label =
            Input.labelAbove [] <|
                Element.text "Diff should show"
        , spellcheck = False
        }


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



--diffOutput : Model -> Element Msg
--diffOutput :
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
