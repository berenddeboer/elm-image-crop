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

        git clone git@github.com:berenddeboer/elm-image-crop.git

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
the cropped image as well. That will require you to include a piece of
javascript. You may also run into CORS issues: you cannot extract part
of an image that does not belong to your website unless that third
party website has told you this is OK.

6. Add two more message: one for the click which initiates
   the action to extract the image, the other to handle the callback
   from JavaScript where the actual extraction process takes place.

   So your Msg looks like this:

        type Msg
            = GotImageCropMsg ImageCrop.Msg
            | SaveProfilePicture
            | GotCroppedImage (Result Decode.Error String)


7. Update your `update` function to handle these, see
   [Main.elm](examples/crop-and-get-cropped-image/src/Main.elm) for an
   example.

8. Add a subscription to handle the callback from JavaScript:

        subscriptions model =
            ImageCrop.Export.croppedImage (decodeUrl >> GotCroppedImage)

        decodeUrl : Decode.Value -> Result Decode.Error String
        decodeUrl =
            Decode.decodeValue Decode.string

    As you can see the callback just returns a url, a data url, of the
    extracted image. You can store this in your model, or use it as
    part of an HTTP request which store the extracted image in a
    backend or so.
