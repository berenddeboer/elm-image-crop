port module ImageCrop.Export exposing
    ( cropImage
    , croppedImage
    )


import Json.Encode as Encode exposing (float, int, object, string)


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
