module ImageCrop exposing
    ( Model
    , Msg
    , update
    , view
    )


{-| Make an ImageCrop component available.

@docs Model
@docs Msg
@docs update
@docs view
-}

import Html exposing (Attribute, Html, div, img, text)
import Html.Attributes as Html exposing (class, src, style)
import Html.Events exposing (on)
import Html.Events.Extra.Touch as Touch
import Html.Lazy exposing (lazy)
import Json.Decode as Json
import Svg exposing (g, path, polyline, svg)
import Svg.Attributes exposing (d, fill, id, opacity, pointerEvents, points, preserveAspectRatio, stroke, strokeWidth, transform, viewBox)
import Svg.Events exposing (onMouseDown, onMouseUp)


-- MODEL

{-| The model to track the internal state of this component.
-}

type alias Model =
    { left : Int
    , top : Int
    , length : Int
    , minimum_length : Int
    , maximum_length : Int
    , image_width : Int
    , image_height : Int
    , natural_width : Int
    , natural_height : Int
    , rectangle_state : RectangleState
    }


type RectangleState
    = AtRest
    | Moving Int Int Int Int
    | Resizing MoveEdge Int Int Int Int Int
    | Pinching Int Int Int ( Float, Float ) ( Float, Float )


type MoveEdge
    = MoveTopLeft
    | MoveTopRight
    | MoveBottomLeft
    | MoveBottomRight

type WindDirection
    = NorthWest
    | NorthEast
    | SouthWest
    | SouthEast


{-| Create an initial model.

`width' and `height' are the dimensions of the image as scaled in the
browser. `natural_width' and `natural_height' are the original dimension
of the image.
-}
initialModel : Float -> Float -> Float -> Float -> Model
initialModel width height natural_width natural_height =
    let
        minimum_length = 100
        proposed_length = round (width / 2)
        int_width = round width
        int_height = round height
        int_natural_width = round natural_width
        int_natural_height = round natural_height
    in
        { left = 0
        , top = 0
        , length =
            if proposed_length >= minimum_length then
                proposed_length
            else
                minimum_length
        , minimum_length = minimum_length
        , maximum_length = min int_width int_height
        , image_width = int_width
        , image_height = int_height
        , natural_width = int_natural_width
        , natural_height = int_natural_height
        , rectangle_state = AtRest
        }



-- VIEW


{-| The view of an image that can be cropped.
-}
view : String -> Maybe Model -> Html Msg
view url maybe_settings =
    div
        [ class "elm-crop-image"
        , style "position" "relative"
        ]
        [ img
          [ src url
          , style "max-width" "100%"
          , onLoad GotImageSize
          , Html.id "elm-image-crop--img"
          ]
          []
        , case maybe_settings of
              Just settings -> viewCropRectangle settings
              Nothing -> text ""
        ]


viewCropRectangle : Model -> Html Msg
viewCropRectangle settings =
    let
        width = settings.image_width

        height = settings.image_height

        length = settings.length

        widthStr = (String.fromInt width)

        heightStr = (String.fromInt height)

        cut_out =
            [ ( 0, settings.image_height )
            , ( width, 0)
            , ( 0, -height)
            , ( -width, 0) -- we should now be at 0, 0)
            , ( settings.left, settings.top )
            , ( length, 0 )
            , ( 0, length )
            , ( -length, 0 )
            , ( 0, -length )
            , ( -settings.left, -settings.top )
            ]

        rectangle =
            [ ( 0, 0 )
            , ( length, 0 )
            , ( 0, length )
            , ( -length, 0 )
            ]

        offset = 7

        resize_marker_length = 15

        corner_length = offset + resize_marker_length + 10

        -- Make corner a bit bigger than the marker, makes it easier to grab
        corner =
            [ ( 0, 0 )
            , ( corner_length, 0 )
            , ( 0, corner_length )
            , ( -corner_length, 0 )
            ]

        topLeftCorner =
            [ ( offset, offset + resize_marker_length )
            , ( offset, offset )
            , ( offset + resize_marker_length, offset )
            ]

        border_color = "white"

        wind_direction move_direction =
            case move_direction of
                MoveTopLeft -> "nw"
                MoveTopRight -> "ne"
                MoveBottomLeft -> "sw"
                MoveBottomRight -> "se"

        draggable_corner move_direction =
            svg
               [ Svg.Attributes.class "corner"
               , Svg.Attributes.x "0"
               , Svg.Attributes.y "0"
               , Svg.Attributes.width ( String.fromInt corner_length )
               , Svg.Attributes.height ( String.fromInt corner_length )
               , Svg.Attributes.style ( "cursor: " ++ (wind_direction move_direction) ++ "-resize" )
               , onMouseDown ( StartResize move_direction )
               , Touch.onStart ( StartResizeByTouch move_direction )
               , onMouseMove RectangleResized
               --, Touch.onMove RectangleResizedByTouch
               , Touch.onMove ( uncurry RectangleResized << touchCoordinates )
               ]
               [ path
                     [ d (pathToString corner )
                     , stroke "transparent"
                     ]
                     []
               , polyline
                     [ points ( pointsToString topLeftCorner )
                     ]
                     []
               ]

        corner_translation move_direction =
            case move_direction of
                MoveTopLeft ->  (0, 0)
                MoveTopRight -> (settings.length, 0)
                MoveBottomLeft -> (0, settings.length)
                MoveBottomRight -> (settings.length, settings.length)

        rotation move_direction =
            case move_direction of
                MoveTopLeft ->  0
                MoveTopRight -> 90
                MoveBottomLeft -> 270
                MoveBottomRight -> 180

        transform_corner move_direction =
            let
                translation =
                    corner_translation move_direction
                        |> (\(x, y) -> (String.fromInt x) ++ ", " ++ (String.fromInt y) )
            in
                transform ( String.concat ["translate(", translation, "), rotate(", String.fromInt (rotation move_direction), ")" ] )

        positioned_corner move_direction =
            g
                [ transform_corner move_direction ]
                [ draggable_corner move_direction ]

    in
    Svg.svg
        [ Svg.Attributes.id "elm-image-crop--svg-overlay"
        , Svg.Attributes.width (widthStr ++ "px")
        , Svg.Attributes.height (heightStr ++ "px")
        , viewBox ( "0 0 " ++ widthStr ++ " " ++ heightStr )
        , Svg.Attributes.style "position: absolute; z-index: 1; top: 0; left: 0;"

        -- We'll capture the mouse move here too in case the mouse moves
        -- outside the rectange, which can easily happen and it's annoying
        -- to have the move and resize stop then
        , case settings.rectangle_state of
              AtRest -> nothing
              Moving _ _ _ _ -> onMouseMove RectangleMoved
              Resizing _ _ _ _ _ _ -> onMouseMove RectangleResized
              Pinching _ _ _ _ _ -> nothing

        , case settings.rectangle_state of
              AtRest -> nothing
              Moving _ _ _ _ -> Touch.onMove RectangleMovedByTouch
              Resizing _ _ _ _ _ _ -> nothing
              Pinching _ _ _ _ _ -> Touch.onMove RectangleResizedByPinch
        , onMouseUp BeAtRest
        , on "touchend" ( Json.succeed BeAtRest )
        , on "touchend" ( Json.succeed BeAtRest )
        -- TODO: should only stop move when there's a mouseout of this element,
        -- not any bubbled element
        , on "mouseleave" (Json.map PossiblyStopMove targetId)
        ]
        [ path
              [ d ( pathToString cut_out )
              , fill "black"
              , opacity "0.55"
              ]
              []
        , svg
              [ Svg.Attributes.x (String.fromInt settings.left)
              , Svg.Attributes.y (String.fromInt settings.top)
              , Svg.Attributes.width (String.fromInt settings.length)
              , Svg.Attributes.height (String.fromInt settings.length)
              , stroke border_color
              , fill "transparent"
              --, Svg.Attributes.class "no-text-select"
              ]
              [ path
                    [ d ( pathToString rectangle )
                    , Svg.Attributes.style "cursor: grab"
                    , onMouseDown StartMove
                    , Touch.onStart StartMoveOrResize
                    , id "elm-imagecrop-cropped-image"
                    ]
                    []
              , lazy positioned_corner MoveTopLeft
              , lazy positioned_corner MoveTopRight
              , lazy positioned_corner MoveBottomLeft
              , lazy positioned_corner MoveBottomRight
              ]
        ]


nothing : Svg.Attribute Msg
nothing =
    Svg.Attributes.attributeName ""


{-| path to string using relative coordinates.
-}
pathToString : List ( Int, Int ) -> String
pathToString coordinates =
    let
        pathCommand index item =
            let
                ( x, y ) = item

                command =
                    if index == 0 then
                        "M"
                    else
                        " l"
            in
                command ++ String.fromInt x ++ " " ++ String.fromInt y

        strings =
            coordinates
                |> List.indexedMap pathCommand
    in
        String.concat strings ++ " Z"


pointsToString : List ( Int, Int ) -> String
pointsToString points =
    points
        |> List.map (\(x, y) -> (String.fromInt x) ++ "," ++ (String.fromInt y))
        |> String.join ","


-- EVENT HANDLERS

{-| Image dimensions are only available after browser has loaded the
image.
-}
onLoad : (Float -> Float -> Float -> Float -> msg) -> Attribute msg
onLoad tagger =
    on "load" (Json.map4 tagger imageWidth imageHeight naturalWidth naturalHeight)


targetId : Json.Decoder String
targetId =
  Json.at ["target", "id"] Json.string


imageWidth : Json.Decoder Float
imageWidth =
    Json.at ["target", "width" ] Json.float


imageHeight : Json.Decoder Float
imageHeight =
    Json.at ["target", "height" ] Json.float


naturalWidth : Json.Decoder Float
naturalWidth =
    Json.at ["target", "naturalWidth" ] Json.float


naturalHeight : Json.Decoder Float
naturalHeight =
    Json.at ["target", "naturalHeight" ] Json.float


onMouseDown : ( Int -> Int -> msg) -> Attribute msg
onMouseDown tagger =
    Svg.Events.on "mousedown" (Json.map2 tagger clientX clientY )


onMouseMove : ( Int -> Int -> msg) -> Attribute msg
onMouseMove tagger =
    Svg.Events.on "mousemove" (Json.map2 tagger clientX clientY )


clientX : Json.Decoder Int
clientX =
    Json.field "clientX" Json.int


clientY : Json.Decoder Int
clientY =
    Json.field "clientY" Json.int


touchCoordinates : Touch.Event -> ( Int, Int )
touchCoordinates touchEvent =
    let
        ( x, y ) =
            List.head touchEvent.changedTouches
                |> Maybe.map .clientPos
                |> Maybe.withDefault ( 0, 0 )
    in
        ( round x, round y )

{- Copied from Elm.Basics 0.18
-}
uncurry : (a -> b -> c) -> (a,b) -> c
uncurry f (a,b) =
  f a b


-- UPDATE

{-| Opaque type for the messages this component uses.
-}
type Msg
    = GotImageSize Float Float Float Float
    | StartMove Int Int
    | PossiblyStopMove String
    | BeAtRest
    | RectangleMoved Int Int
    | StartResize MoveEdge Int Int
    | RectangleResized Int Int
    | StartMoveOrResize Touch.Event
    | StartResizeByTouch MoveEdge Touch.Event
    | RectangleMovedByTouch Touch.Event
    | RectangleResizedByTouch Touch.Event
    | RectangleResizedByPinch Touch.Event


{-| Handle the commands.
-}
update : Msg -> Maybe Model -> ( Maybe Model, Cmd Msg )
update msg maybe_model =
    case maybe_model of
        Nothing ->
            case msg of
                GotImageSize width height natural_width natural_height ->
                    ( Just ( initialModel width height natural_width natural_height ), Cmd.none )
                _ ->
                    ( Nothing, Cmd.none )
        Just model ->
            case msg of
                GotImageSize _ _ _ _ ->
                    ( maybe_model, Cmd.none )

                StartMove clientx clienty ->
                    ( Just { model | rectangle_state = Moving model.left model.top clientx clienty }, Cmd.none )

                BeAtRest ->
                    ( Just { model | rectangle_state = AtRest }, Cmd.none )

                PossiblyStopMove id ->
                    if id == "elm-image-crop--svg-overlay" then
                        ( Just { model | rectangle_state = AtRest }, Cmd.none )
                    else
                        ( maybe_model, Cmd.none )

                RectangleMoved clientx clienty ->
                    case model.rectangle_state of
                        Moving originalx originaly startx starty ->
                            let
                                proposed_left = originalx + clientx - startx
                                proposed_top = originaly + clienty - starty
                                left =
                                    if proposed_left < 0 then
                                        0
                                    else
                                        if proposed_left + model.length >= model.image_width then
                                            model.image_width - model.length
                                        else
                                            proposed_left
                                top =
                                    if proposed_top < 0 then
                                        0
                                    else
                                        if proposed_top + model.length >= model.image_height then
                                            model.image_height - model.length
                                        else
                                            proposed_top
                            in
                                ( Just { model | left = left, top = top }, Cmd.none )
                        _ ->
                            ( maybe_model, Cmd.none )

                StartResize edge clientx clienty ->
                    ( Just { model | rectangle_state = Resizing edge model.left model.top model.length clientx clienty }, Cmd.none )

                RectangleResized clientx clienty ->
                    case model.rectangle_state of
                        Resizing corner original_left original_top original_length startx starty ->
                            updateRectangleResizedByCorners maybe_model model corner original_left original_top original_length startx starty clientx clienty
                        _ ->
                            ( maybe_model, Cmd.none )

                StartMoveOrResize event ->
                    let
                        rest = ( Just { model | rectangle_state = AtRest }, Cmd.none )
                    in
                        case event.targetTouches of
                            [] -> rest
                            [ single_touch ] ->
                                let
                                    ( clientx, clienty ) = single_touch.clientPos
                                in
                                    update (StartMove (round clientx) (round clienty) ) maybe_model
                            first_touch :: more_touches ->
                                case more_touches of
                                    [] -> rest -- impossible case
                                    [ second_touch ] ->
                                        ( Just { model | rectangle_state = Pinching model.left model.top model.length first_touch.clientPos second_touch.clientPos }, Cmd.none )
                                        --( Just { model | rectangle_state = AtRest }, Cmd.none )
                                    _ :: _ -> rest -- multitouch, reset what we're doing

                RectangleMovedByTouch event ->
                    let
                        rest = ( Just { model | rectangle_state = AtRest }, Cmd.none )
                    in
                        case event.touches of
                            [] -> rest
                            [ single_touch ] ->
                                let
                                    ( clientx, clienty ) = single_touch.clientPos
                                in
                                    update (RectangleMoved (round clientx) (round clienty) ) maybe_model
                            _ :: _ -> rest

                StartResizeByTouch edge event ->
                    let
                        rest = ( Just { model | rectangle_state = AtRest }, Cmd.none )
                    in
                        case event.targetTouches of
                            [] -> rest
                            [ single_touch ] ->
                                let
                                    ( clientx, clienty ) = single_touch.clientPos
                                in
                                    update (StartResize edge (round clientx) (round clienty) ) maybe_model
                            _ :: _ -> rest

                RectangleResizedByTouch event ->
                        case List.head event.changedTouches of
                            Just touch ->
                                let
                                    ( clientx, clienty ) = touch.clientPos
                                in
                                    update (RectangleResized (round clientx) (round clienty) ) maybe_model
                            Nothing ->
                                ( maybe_model, Cmd.none )

                RectangleResizedByPinch event ->
                    let
                        impossible_case = ( maybe_model, Cmd.none )
                    in
                    case model.rectangle_state of
                        Pinching original_left original_top original_length original_first_touch original_second_touch ->
                            case event.targetTouches of
                                [] -> impossible_case
                                [ _ ] -> impossible_case
                                first_touch :: more_touches ->
                                    case more_touches of
                                        [] -> impossible_case
                                        [ second_touch ] ->
                                            updateRectangleResizedByPinch model original_left original_top original_length original_first_touch original_second_touch first_touch second_touch
                                        _ :: _ -> impossible_case
                        _ ->
                            impossible_case



{- Handle update when user resizes rectangle by dragging corners.

We pass in `maybe_model` only for efficiency sake so Elm doesn't think
model has changed, and therefore redraws.
-}
updateRectangleResizedByCorners maybe_model model corner original_left original_top original_length startx starty clientx clienty =
    let
        delta_x = clientx - startx
        delta_y = clienty - starty

        direction =
            if delta_x <= 0 then
                if delta_y <= 0 then
                    NorthWest
                else
                    SouthWest
            else
                if delta_y <= 0 then
                    NorthEast
                else
                    SouthEast

        -- We use 0 to cancel out forbidden directions
        sign =
            case ( corner, direction ) of
                ( MoveTopLeft, NorthWest ) -> 1
                ( MoveTopLeft, SouthEast ) -> -1
                ( MoveTopRight, NorthEast ) -> 1
                ( MoveTopRight, SouthWest ) -> -1
                ( MoveBottomLeft, SouthWest ) -> 1
                ( MoveBottomLeft, NorthEast ) -> -1
                ( MoveBottomRight, SouthEast ) -> 1
                ( MoveBottomRight, NorthWest ) -> -1
                ( _, _ ) -> 0

        allowed_move = sign /= 0

        -- Using the actual distance doesn't work, as it grows faster then the drag
        d = sign * (min (abs delta_x) (abs delta_y))

        proposed_delta =
            if original_length + d >= model.minimum_length then
                d
            else
                model.minimum_length - original_length

        -- Cap delta so we don't move outside image
        delta =
            case corner of
                MoveTopLeft ->
                    if original_left - proposed_delta < 0 || original_top - proposed_delta < 0 then
                        min original_left original_top
                    else
                        proposed_delta
                MoveTopRight ->
                    if original_top - proposed_delta < 0 || original_left + original_length + proposed_delta > model.image_width then
                        min original_top (model.image_width - original_left - original_length)
                    else
                        proposed_delta
                MoveBottomLeft ->
                    if original_left - proposed_delta < 0 || original_top + proposed_delta > model.image_height then
                        min original_left (model.image_height - original_top)
                    else
                        proposed_delta
                MoveBottomRight ->
                    if original_left + original_length + proposed_delta > model.image_width || original_top + original_length + proposed_delta > model.image_height then
                        min (model.image_width - original_left - original_length) (model.image_height - original_top - original_length)
                    else
                        proposed_delta

        new_length = original_length + delta

        ( new_left, new_top ) =
            case corner of
                MoveTopLeft ->
                    ( original_left - delta, original_top - delta )
                MoveTopRight ->
                    ( original_left, original_top - delta )
                MoveBottomLeft ->
                    ( original_left - delta, original_top )
                MoveBottomRight ->
                    ( original_left, original_top )

    in
        if allowed_move && delta /= 0 then
            ( Just { model | left = new_left, top = new_top, length = new_length }, Cmd.none )
        else
            ( maybe_model, Cmd.none )


{- Handle update for when user resizes the rectangle by pinching.
-}
updateRectangleResizedByPinch model original_left original_top original_length original_first_touch original_second_touch first_touch second_touch =
    let

        original_distance = distance original_first_touch original_second_touch

        pinch_distance = distance first_touch.clientPos second_touch.clientPos
        proposed_delta = pinch_distance - original_distance

        delta =
            if original_length + proposed_delta >= model.minimum_length then
                proposed_delta
            else
                model.minimum_length

        -- Calculate by how much the left edge should move if the user had moved the rectangle.
        -- Note that this number is negative when the rectangle gets bigger.
        proposed_left_delta = round (min (Tuple.first first_touch.clientPos - Tuple.first original_first_touch) (Tuple.first second_touch.clientPos - Tuple.first original_second_touch))

        proposed_top_delta = round (min (Tuple.second first_touch.clientPos - Tuple.second original_first_touch) (Tuple.second second_touch.clientPos - Tuple.second original_second_touch))

        -- How much should the left edge move if the user didn't move the triangle?
        -- Note that this number is positive when the rectangle gets bigger.
        position_delta_without_move = round (toFloat delta / 2)

        -- Move the left and top edges out by only that bit which the user didn't move
        left_delta =
            -position_delta_without_move + proposed_left_delta

        top_delta =
            -position_delta_without_move + proposed_top_delta

        -- Make sure new_length never exceeds the maximum
        new_length =
            clamp model.minimum_length model.maximum_length (original_length + delta)

        -- If left bumps into left edge, don't go past it, but grow to the right, and vice versa
        new_left =
            if original_left + left_delta >= 0 then
                if original_left + left_delta + new_length <= model.image_width then
                    original_left + left_delta
                else
                    model.image_width - new_length
            else
                0

        -- Same for top, make sure rectangle stays inside image.
        -- If image has reached max width we get a bit of a weird
        -- effect that the top moves upward, without the user giving a
        -- clear pinch move upward.
        new_top =
            if original_top + top_delta >= 0 then
                if original_top + top_delta + new_length <= model.image_height then
                    original_top + top_delta
                else
                    model.image_height - new_length
            else
                0

    in
        ( Just { model | length = new_length, left = new_left, top = new_top }, Cmd.none )



{- Calculate distance between two points.

See: https://www.wikihow.com/Find-the-Distance-Between-Two-Points
-}
distance : ( Float, Float ) -> ( Float, Float ) -> Int
distance ( x1, y1 ) ( x2, y2 ) =
    round ( sqrt ( (x2 - x1)^2 + (y2 - y1)^2 ) )


distance_int : Int -> Int -> Int -> Int -> Int
distance_int x1 y1 x2 y2 =
    round ( sqrt (toFloat ( (x2 - x1)^2 + (y2 - y1)^2 ) ) )
