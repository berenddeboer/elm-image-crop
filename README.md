# Elm image cropper

Allow a user to crop the given image. Mobile first design, so simply
use the double pinch to resize and move. Also supports desktop and mouse.


## Screenshots

<img src="https://raw.githubusercontent.com/berenddeboer/elm-image-crop/master/screenshot_1.png" />


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

1. Add `GotImageCropMsg` to your `Msg` type.

2. Add a div to your view:

        div
          [ class "image-crop-picture"
          , style "max-width" "100%"
          ]
          [ Html.map GotImageCropMsg ( ImageCrop.view model.url model.cropSettings) ]

3. Handle this new msg in your `update` function:

        case msg of
            GotImageCropMsg subMsg ->
                let
                    ( cropSettings, cmd ) = ImageCrop.update subMsg model.cropSettings
                in
                    ( { model | cropSettings = cropSettings } )
