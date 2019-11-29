port module ImageCrop.Export exposing
    ( cropImage
    , cropImageDefault
    , croppedImage
    )


import Json.Encode as Encode exposing (float, int, object, string)


{-| `cropImageDefault` can just be given a `CropSettings` and assumes
some sensible defaults to call `cropImage`.
-}
cropImageDefault :
    { a | natural_width : Int
    , natural_height : Int
    , image_width : Int
    , image_height : Int
    , left : Int
    , top : Int
    , length : Int }
    -> Cmd msg
cropImageDefault { natural_width, natural_height, image_width, image_height, left, top, length } =
    let
        x_scale =
            if natural_width > image_width then
                toFloat natural_width / toFloat image_width
            else
                1
        y_scale =
            if natural_height > image_height then
                toFloat natural_height / toFloat image_height
            else
                1
        rounded_left = round ( toFloat left * x_scale )
        rounded_top = round ( toFloat top * y_scale )
        width = round ( toFloat length * x_scale )
        height = round ( toFloat length * y_scale )
    in
        cropImage "elm-image-crop--img" rounded_left rounded_top width height natural_width natural_height length length  "image/jpeg" 0.9



{-| Perform the actual crop. This is done using JavaScript as Elm does
not support canvas.

left, top, width and height is the part of the image to be cropped. It
is expressed in the natural dimensions of the image, not in the units
as scaled down or up by the browser.

`image_width' and `image_height' are the natural dimensions of the image.

`destination_width' and `destination_height' are the dimensions of the
cropped image and allow for scaling.

If the mime type is unsupported, the image will be returned as image/png.
-}
cropImage : String -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> String -> Float -> Cmd msg
cropImage image_id left top width height image_width image_height destination_width destination_height mime_type quality =
    doCropImage
        ( object
              [ ("image_id", string image_id)
              , ("left", int left)
              , ("top", int top)
              , ("width", int width)
              , ("height", int height)
              , ("image_width", int image_width)
              , ("image_height", int image_height)
              , ("destination_width", int destination_width)
              , ("destination_height", int destination_height)
              , ("mime_type", string mime_type)
              , ("quality", float quality)
              ]
        )


port doCropImage : Encode.Value -> Cmd msg

port croppedImage : (Encode.Value -> msg) -> Sub msg
