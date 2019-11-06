# Elm image cropper

Allow a user to crop the given image. Mobile friendly. Supports resize, and double pinch.

# Installation

This image crop cannot be installed with `elm` as it has to use a port
module, because Elm does not support Canvas. So you'll have to install it manually.

In your Elm application root directory:

    elm clone git@github.com:berenddeboer/elm-image-crop.git

Then add `elm.json` so to list the directory under your "source directories", something like this:

    "source-directories": [
        "src",
        "elm-image-scrop"
    ],



# Usage

See the `examples` directory.


Basic steps:

# Add `GotImageCropMsg` to your `Msg` type.

# Add a div to your view:

    div
      [ class "image-crop-picture"
      , style "max-width" "100%"
      ]
      [ Html.map GotImageCropMsg ( ImageCrop.view model.url model.cropSettings) ]

# Handle this new msg in your `update` function:

    case msg of
        GotImageCropMsg subMsg ->
            let
                ( cropSettings, cmd ) = ImageCrop.update subMsg model.cropSettings
            in
                ( { model | cropSettings = cropSettings } )
