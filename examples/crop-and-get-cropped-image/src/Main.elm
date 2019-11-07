module Main exposing (..)

-- Basic example of how to use the ImageCrop module.

import Browser
import Html exposing (Html, button, div, img, pre, text)
import Html.Attributes exposing (class, src, style)
import Html.Events exposing (onClick)
import ImageCrop
import ImageCrop.Export exposing (cropImage)
import Json.Decode as Decode



-- MAIN


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { url : String
    , cropSettings : Maybe ImageCrop.Model
    , extractedImageUrl : Maybe String
    , error : Maybe String
    }


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { url = "pinnacles.jpg"
      , cropSettings = Nothing
      , extractedImageUrl = Nothing
      , error = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = GotImageCropMsg ImageCrop.Msg
    | SaveProfilePicture
    | GotCroppedImage (Result Decode.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotImageCropMsg subMsg ->
            let
                ( cropSettings, cmd ) =
                    ImageCrop.update subMsg model.cropSettings
            in
            ( { model | cropSettings = cropSettings }, Cmd.none )

        SaveProfilePicture ->
            case model.cropSettings of
                Just crop_settings ->
                    let
                        x_scale =
                            if crop_settings.natural_width > crop_settings.image_width then
                                toFloat crop_settings.natural_width / toFloat crop_settings.image_width

                            else
                                1

                        y_scale =
                            if crop_settings.natural_height > crop_settings.image_height then
                                toFloat crop_settings.natural_height / toFloat crop_settings.image_height

                            else
                                1

                        left =
                            round (toFloat crop_settings.left * x_scale)

                        top =
                            round (toFloat crop_settings.top * y_scale)

                        width =
                            round (toFloat crop_settings.length * x_scale)

                        height =
                            round (toFloat crop_settings.length * y_scale)
                    in
                    ( model, cropImage "elm-image-crop--img" left top width height crop_settings.natural_width crop_settings.natural_height crop_settings.length crop_settings.length "image/jpeg" 0.9 )

                Nothing ->
                    ( model, Cmd.none )

        GotCroppedImage result ->
            case result of
                Ok url ->
                    ( { model | extractedImageUrl = Just url }, Cmd.none )

                Err _ ->
                    ( { model | error = Just "Could not extract image." }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div
        []
        [ div
            [ class "image-crop-picture"
            , style "max-width" "100%"
            ]
            [ Html.map GotImageCropMsg (ImageCrop.view model.url model.cropSettings) ]
        , button
            [ onClick SaveProfilePicture
            , style "display" "block"
            ]
            [ text "Save" ]
        , case model.extractedImageUrl of
            Just url ->
                img [ src url ] []

            Nothing ->
                text ""
        , case model.error of
            Just s ->
                pre [] [ text s ]

            Nothing ->
                text ""
        ]



-- SUBSCRIPTIONS


subscriptions model =
    ImageCrop.Export.croppedImage (decodeUrl >> GotCroppedImage)


decodeUrl : Decode.Value -> Result Decode.Error String
decodeUrl =
    Decode.decodeValue Decode.string
