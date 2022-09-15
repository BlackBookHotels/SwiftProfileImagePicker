//
//  UIImage+Cropping.swift
//
//
//  Copyright © 2016 William Miller, http://millermobilesoft.com/
//  email:<support@millermobilesoft.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import CoreGraphics

extension UIImage { // (Cropping)
    
    /** scale size
     *  calculates a return size by aspect scaling the fromSize to fit within the destination size while giving priority to the width or height depending on which preference will maintain both the return width and height within the destination ie the return size will return a new size where both width and height are less than or equal to the destinations.
     *
     *  @param fromSize Size to be transforme
     *  @param toSize   Destination size
     *
     *  @return Aspect scaled size
     */
    //+(CGSize)scaleSize:(CGSize)fromSize toSize:(CGSize)toSize;
    
    /** crop rectangle
     *  returns a new UIImage cut from the cropArea of the underlying image.  It first scales the underlying image to the scale size before cutting the crop area from it. The returned CGImage is in the dimensions of the cropArea and it is oriented the same as the underlying CGImage as is the imageOrientation.
     *
     *  @param cropArea  the rectangle with in the frame size to crop.
     *  @param frameSize The size of the frame that is currently showing the image
     *
     *  @return A UIImage cropped to the input dimensions and oriented like the UIImage.
     */
    //func UIImage*)cropRectangle:(CGRect)cropArea inFrame:(CGSize)frameSize;
    
    /**
     * transposeCropRect:fromBound:toBound transposes the origin of the crop rectangle to match the orientation of the underlying CGImage. For some orientations, the height and width are swaped.
     *
     *  @param cropRect The crop rectangle as layed out on the screen.
     *  @param fromRect The rectangle the crop rect sits inside.
     *  @param toRect   The rectangle the crop rect will be removed from
     *
     *  @return The crop rectangle scaled to the rectangle.
     */
    func scaleSize(fromSize: CGSize,
                   toSize: CGSize) -> CGSize {    

        var scaleSize:CGSize = .zero
        
        // if the wideth is the shorter dimension
        if (toSize.width < toSize.height) {
            
            if (fromSize.width >= toSize.width) {  // give priority to width if it is larger than the destination width
                
                scaleSize.width = round(toSize.width)
                
                scaleSize.height = round(scaleSize.width * fromSize.height / fromSize.width)
                
            } else if (fromSize.height >= toSize.height) {  // then give priority to height if it is larger than destination height
                
                scaleSize.height = round(toSize.height);
                
                scaleSize.width = round(scaleSize.height * fromSize.width / fromSize.height);
                
            } else {  // otherwise the source size is smaller in all directions.  Scale on width
                
                scaleSize.width = round(toSize.width)
                
                scaleSize.height = round(scaleSize.width * fromSize.height / fromSize.width)
                
                if (scaleSize.height > toSize.height) { // but if the new height is larger than the destination then scale height
                    
                    scaleSize.height = round(toSize.height)
                    
                    scaleSize.width = round(scaleSize.height * fromSize.width / fromSize.height)
                }
                
            }
        } else {  // else height is the shorter dimension
            
            if (fromSize.height >= toSize.height) {  // then give priority to height if it is larger than destination height
                
                scaleSize.height = round(toSize.height)
                
                scaleSize.width = round(scaleSize.height * fromSize.width / fromSize.height)
                
            } else if (fromSize.width >= toSize.width) {  // give priority to width if it is larger than the destination width
                
                scaleSize.width = round(toSize.width)
                
                scaleSize.height = round(scaleSize.width * fromSize.height / fromSize.width)
                
                
            } else {  // otherwise the source size is smaller in all directions.  Scale on width
                
                scaleSize.width = round(toSize.width)
                
                scaleSize.height = round(scaleSize.width * fromSize.height / fromSize.width)
                
                if (scaleSize.height > toSize.height) { // but if the new height is larger than the destination then scale height
                    
                    scaleSize.height = round(toSize.height)
                    
                    scaleSize.width = round(scaleSize.height * fromSize.width / fromSize.height)
                }
                
            }
            
        }
        
        return scaleSize
    }
    
    /** scale bitmap to size
     *  returns an UIImage scaled to the input dimensions. Oftentimes the underlining CGImage does not match the orientation of the UIImage. This routing scales the UIImage dimensions not the CGImage's, and so it swaps the height and width of the scale size when it detects the UIImage is oriented differently.
     *
     *  @param scaleSize the dimensions to scale the bitmap to.
     *
     *  @return A reference to a uimage created from the scaled bitmap
     */
    func scaleBitmap(toSize scaleSize: CGSize) -> UIImage?
    {
        guard let cgImage = self.cgImage,
              let colorSpace = cgImage.colorSpace  else  { return nil }

        /* round the size of the underlying CGImage and the input size.
         */
        var scaleSize = CGSize(width: round(scaleSize.width), height: round(scaleSize.height))
        
        /* if the underlying CGImage is oriented differently than the UIImage then swap the width and height of the scale size. This method assumes the size passed is a request on the UIImage's orientation.
         */
        if ([.left, .right].contains(self.imageOrientation)) {
            
            scaleSize = CGSize(width: round(scaleSize.height), height: round(scaleSize.width))
        }
        
        /* Create a bitmap context in the dimensions of the scale size and draw the underlying CGImage into the context.
         */
        
        let context:CGContext? = CGContext(data: nil, width:  Int(scaleSize.width), height: Int(scaleSize.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue)
 
        var returnImg:UIImage? = nil
                
        if let context = context {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: scaleSize.width, height: scaleSize.height))
            
            /* realize the CGImage from the context.
             */
            if let imgRef = context.makeImage()
            {            
                /* realize the CGImage into a UIImage. */
                returnImg = UIImage(cgImage: imgRef)
            }
            
        } else {
            
            /* context creation failed, so return a copy of the image, and log the error. */
            NSLog("NULL Bitmap Context in scaleBitmapToSize")
            
            returnImg = UIImage(cgImage: cgImage)
        }
        
        return returnImg;
    }
    
    /* transposeCropRect:fromBound:toBound transposes the origin of the crop rectangle to match the orientation of the underlying CGImage. For some orientations, the height and width are swaped.
     */
    func transposeCropRect(
        cropRect: CGRect,
        fromRect: CGRect,
        toRect: CGRect) -> CGRect {
        
            let scale:CGFloat = toRect.size.width / fromRect.size.width
        
            return CGRect(x: round(cropRect.origin.x * scale), y: round(cropRect.origin.y*scale), width: round(cropRect.size.width*scale), height: round(cropRect.size.height*scale))
        
    }
    
    /* orientCropRect:inDimension: transposes the origin of the crop rectangle to match the orientation of the underlying CGImage. For some orientations, the height and width are swaped.
     */
    func transposeCropRect(
        cropRect: CGRect,
        inDimension boundSize: CGSize,
        forOrientation orientation: UIImage.Orientation) -> CGRect {
        
        var transposedRect = cropRect
        
        switch (orientation) {
        case .left:
            transposedRect.origin.x = boundSize.height - (cropRect.size.height + cropRect.origin.y);
            transposedRect.origin.y = cropRect.origin.x;
            transposedRect.size = CGSize(width: cropRect.size.height, height: cropRect.size.width);
            break;
            
        case .right:
            transposedRect.origin.x = cropRect.origin.y;
            transposedRect.origin.y = boundSize.width - (cropRect.size.width + cropRect.origin.x);
            transposedRect.size = CGSize(width: cropRect.size.height, height: cropRect.size.width);
            break;
            
        case .down:
            transposedRect.origin.x = boundSize.width - (cropRect.size.width + cropRect.origin.x);
            transposedRect.origin.y = boundSize.height - (cropRect.size.height + cropRect.origin.y);
            break;
            
        case .up:
            break;
            
        case .downMirrored:
            transposedRect.origin.x = cropRect.origin.x;
            transposedRect.origin.y = boundSize.height - (cropRect.size.height + cropRect.origin.y);
            break;
            
        case .leftMirrored:
            transposedRect.origin.x = cropRect.origin.y;
            transposedRect.origin.y = cropRect.origin.x;
            transposedRect.size = CGSize(width: cropRect.size.height, height: cropRect.size.width);
            break;
            
        case .rightMirrored:
            transposedRect.origin.x = boundSize.height - (cropRect.size.height + cropRect.origin.y);
            transposedRect.origin.y = boundSize.width - (cropRect.size.width + cropRect.origin.x);
            transposedRect.size = CGSize(width: cropRect.size.height, height: cropRect.size.width);            
            break;
            
        case .upMirrored:
            transposedRect.origin.x = boundSize.width - (cropRect.size.width + cropRect.origin.x);
            transposedRect.origin.y = cropRect.origin.y;
            break;
            
            
        default:
            break;
        }
        
        return transposedRect
    }
    /* cropRectangle:inFrame returns a new UIImage cut from the cropArea of the underlying image.  It first scales the underlying image to the scale size before cutting the crop area from it. The returned CGImage is in the dimensions of the cropArea and it is oriented the same as the underlying CGImage as is the imageOrientation.
     */
    func cropRectangle(cropRect: CGRect,
                       inFrame: CGSize) -> UIImage? {
        
        let frameSize: CGSize = CGSize(width: round(inFrame.width), height: round(inFrame.height))
        
        /* resize the image to match the zoomed content size */
        let img: UIImage? = scaleBitmap(toSize:frameSize)
        
        /* crop the resized image to the crop rectangel.
         */
        if let cropRef:CGImage = img?.cgImage?.cropping(
            to: transposeCropRect(cropRect: cropRect,
                                  inDimension: frameSize,forOrientation: self.imageOrientation)) {
    
                let croppedImg:UIImage = UIImage(cgImage: cropRef, scale: 1.0, orientation: imageOrientation)
            
            return croppedImg
            
        }
        
        return nil
    }
}
