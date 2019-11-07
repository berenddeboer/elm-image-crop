# Elm image cropper

Allow a user to crop the given image. Mobile first design, so simply
use one fingers to move, and two fingers to resize. Also supports
desktop and mouse.


## Screenshots

<img src="https://raw.githubusercontent.com/berenddeboer/elm-image-crop/master/screenshot_1.png" />


# Installation

This image crop cannot be installed with `elm` as it has to use a port
module, because Elm does not support Canvas. So you'll have to install it manually.

1. In your Elm application root directory:

        elm clone git@github.com:berenddeboer/elm-image-crop.git

2. Then add `elm.json` so to list the directory under your "source directories", something like this:

        "source-directories": [
            "src",
            "elm-image-scrop"
        ],

3. Add the following dependencies to your project:

        elm install elm/json
        elm install elm/svg
        elm install mpizenberg/elm-pointer-events


# Just cropping

See the `examples` directory.


Basic steps:

1. Import the CropImage module to your module.

2. Add an `ImageCrop.Model` type to your model.

3. Add `GotImageCropMsg` to your `Msg` type.

4. Add a div to your view:

        div
          [ class "image-crop-picture"
          , style "max-width" "100%"
          ]
          [ Html.map GotImageCropMsg ( ImageCrop.view model.url model.cropSettings) ]

5. Handle this new msg in your `update` function:

        case msg of
            GotImageCropMsg subMsg ->
                let
                    ( cropSettings, cmd ) = ImageCrop.update subMsg model.cropSettings
                in
                    ( { model | cropSettings = cropSettings } )


# Retrieving the cropped image

Letting a user crop the image is just step one. You want to retrieve
the cropped image as well. That will require some javascript.
