"use strict";

/**
 * Return data url of cropped image.
 *
 * Thanks: https://yellowpencil.com/blog/cropping-images-with-javascript/
 */
export function image_crop_cropped_image (data) {
  const tnCanvas = document.createElement('canvas');
  const tnCanvasContext = tnCanvas.getContext('2d');
  tnCanvas.width = data.destination_width;
  tnCanvas.height = data.destination_height;
  const bufferCanvas = document.createElement('canvas');
  const bufferContext = bufferCanvas.getContext('2d');
  const imgObj = document.getElementById(data.image_id)
  bufferCanvas.width = data.image_width;
  bufferCanvas.height = data.image_height;
  bufferContext.drawImage(imgObj, 0, 0);
  tnCanvasContext.drawImage(bufferCanvas, data.left, data.top, data.width, data.height, 0, 0, data.destination_width, data.destination_height);
  const url = tnCanvas.toDataURL(data.mime_type, data.quality);
  return url;
}
