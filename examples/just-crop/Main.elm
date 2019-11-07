module Main exposing (..)

-- Basic example of how to use the ImageCrop module.

import Browser
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import ImageCrop



-- MAIN


main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model =
    { url : String
    , cropSettings : Maybe ImageCrop.Model
    }


init : Model
init =
    { url = "https://github.com/Foliotek/Croppie/raw/master/demo/demo-1.jpg"
    , cropSettings = Nothing
    }



-- UPDATE


type Msg
    = GotImageCropMsg ImageCrop.Msg


update : Msg -> Model -> Model
update msg model =
    case msg of
        GotImageCropMsg subMsg ->
            let
                ( cropSettings, cmd ) =
                    ImageCrop.update subMsg model.cropSettings
            in
            { model | cropSettings = cropSettings }



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "image-crop-picture"
        , style "max-width" "100%"
        ]
        [ Html.map GotImageCropMsg (ImageCrop.view model.url model.cropSettings) ]
