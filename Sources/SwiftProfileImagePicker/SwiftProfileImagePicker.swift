//
//  SwfitProfileImagePicker.swift
//  SwiftProfileImagePicker
//
//  Created by Richard Kirby on 9/11/22.
//

import Foundation
import UIKit
import AVFoundation
import MobileCoreServices
import MMSCameraViewController

let kOverlayInset:CGFloat = 10

public protocol SwiftProfileImagePickerDelegate {
    /**
     *  The user canceled out of the image selection operation.
     *
     *  @param picker Reference to the Profile Picker
     */
    func swiftImagePickerControllerDidCancel(_ picker: SwiftProfileImagePicker)
    //-(void)mmsImagePickerControllerDidCancel:(MMSProfileImagePicker * _Nonnull)picker;

    /**
     *  The user completed the operation of either editing, selecting from photo library, or capturing from the camera.  The dictionary uses the editing information keys used in UIImagePickerController.
     *
     *  @param picker Reference to profile picker that completed selection.
     *  @param info   A dictionary containing the original image and the edited image, if an image was picked; The dictionary also contains any relevant editing information. .
     */
    func swiftImagePickerController(_ picker: SwiftProfileImagePicker,
                                    didFinishPickingMediaWithInfo info: Dictionary<UIImagePickerController.InfoKey, Any>)

}

public class SwiftProfileImagePicker: UIViewController, UIScrollViewDelegate
{    
    public var delegate: SwiftProfileImagePickerDelegate?
    
    /**
     *  Determines how small the image can be scaled.  The default is 1 i.e. it can be made smaller than original.
     */
    public var minimumZoomScale: CGFloat = 1
    
    /**
     *  Determines how large the image can be scaled.  The default is 10.
     */
    public var maximumZoomScale: CGFloat = 10

    /**
     *  A value from 0 to 1 to control how brilliant the image shows through the area outside of the crop circle.
     *  1 is completely opaque and 0 is completely transparent.  The default is .6.
     */
    public var overlayOpacity: Float = 0.6

    /**
     *  The background color of the edit screen.  The default is black.
     */
    public var backgroundColor: UIColor = .black

    /**
     *  The foreground color of the text on the edit screen. The default is white.
     */
    public var foregroundColor: UIColor = .white    
    
    /**
     *  displays the circle mask
     */
    internal var overlayView: UIView = UIScrollView(frame: .zero)
    
    /**
     *  holds the image to be moved and cropped
     */
    internal var imageView: UIImageView = UIImageView(frame: .zero)
    
    /**
     *  Holds the image for positioning and reasizing
     */
    internal var scrollView: UIScrollView = UIScrollView(frame: .zero)
    
    /**
     *  Image passed to the edit screen.
     */
    internal var imageToEdit: UIImage? = nil
    
    /**
     *  @"Move and Scale";
     */
    internal var titleLabel: UILabel?
    
    /**
     *  selects the image
     */
    internal var chooseButton: UIButton?
    
    /**
     *  cancels cropping
     */
    internal var cancelButton: UIButton?
    
    /**
     *  Rectangular area identifying the crop region
     */
    internal var cropRect: CGRect = .zero
    
    /**
     *  This class proxy's for the UIImagePickerController
     */
    internal var imagePicker: UIImagePickerController?
    
    /**
     *
     */
    internal var camera: MMSCameraViewController?
    
    /**
     *  Session for captureing a still image
     */
    internal var session: AVCaptureSession? = nil
    
    /**
     *  holds the still image from the camera
     */
    internal var stillImageOutput: AVCaptureStillImageOutput? = nil
    
    /**
     *  Is displaying the photo picker
     */
    internal var isDisplayFromPicker: Bool = false
    
    /**
     *  to determine if the crop screen is displayed from the camera path
     */
    internal var isPresentingCamera: Bool = false
    
    /**
     *  to determine if the crop screen is displayed from the camera path
     */
    internal var didChooseImage: Bool = false
    
    /**
     *  true when the snap photo target has been replaced in the UIImagePickerController
     */
    internal var isSnapPhotoTargetAdded: Bool = false
    
    /**
     *  Set to true when camera has been initialized, so it only happens once.
     */
    internal var isPreparingStill: Bool = false
    
    /**
     *  The view controller that presented the MMSImagePickerController
     */
    internal var presentingVC: UIViewController?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        createSubViews()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        positionImageView()
    }
    
    /**
     *  Based on whether displaying the camera, photo library selection, or just editing an image, it dismisses the controllers displayed to support that in the proper sequence.
     *
     *  @param flag       Pass yes to animate the transition.
     *  @param completion The block to execute after the controller is dismissed.
     */
    public override func dismiss(animated flag: Bool, 
                          completion: (() -> Void)? = nil) {
        if (isPresentingCamera) {
            
            super.dismiss(animated: false, completion: completion)
            
            if (didChooseImage) {
                camera?.dismiss(animated: false, completion: {
                    self.isPresentingCamera = false
                    self.didChooseImage = false
                    
                })
            }
            
            
        } else if (isDisplayFromPicker) {
            super.dismiss(animated: false, 
                          completion: {
                self.didChooseImage = false
            })
            
            imagePicker?.dismiss(animated: false)
            
            
            isDisplayFromPicker = false
            
        } else {
            super.dismiss(animated: flag, completion: {
                completion?()
                self.didChooseImage = false
            })
        }
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    /* positionImageView: positions the image view to fit within the center of the screen
     */
    func positionImageView() {
        /* create the scrollView to fit within the physical screen size
         */
        
        guard let imageToEdit = imageToEdit else { return }
        
        let screenRect = UIScreen.main.bounds  // get the device physical screen dimensions
        
        imageView.image = imageToEdit
        
        /* calculate the frame  of the image rectangle.  Depending on the orientation of the image and screen and the image's aspect ratio, either the height will fill the screen or the width. The image view is centered on the screen.  Either the height will fill the screen or the width. The dimension sized less than the enclosing rectangle will have equal insets above and below or left and right such that the image when unzooming can be positioned at the top bounder of the circle.
         */
        
        let imageSize = imageToEdit.scaleSize(fromSize: imageToEdit.size, toSize: screenRect.size)
        
        
        let imageRect:CGRect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        
        imageView.frame = imageRect;
        
        // Compute crop rectangle.
        cropRect = centerSquareRectInRect(layerSize: screenRect.size, withInsets: UIEdgeInsets(top: kOverlayInset, left: kOverlayInset, bottom: kOverlayInset, right: kOverlayInset))
        
        // compute the scrollView's insets to center the crop rect on the screen and so that the image can be scrolled to the edges of the crop rectangle.
        let insets:UIEdgeInsets = insetsForImage(imageSize: imageSize, withFrame: cropRect.size, inView: screenRect.size)

        scrollView.contentInset = insets
        
        scrollView.contentSize = imageRect.size;
        
        scrollView.contentOffset = center(rect: imageRect, 
                                          inside: screenRect)        
    }
}

/// mark - View setup and initialization


extension SwiftProfileImagePicker {
    
    /**
     *  createSubViews: creates and positions the subviews to present functionality for moving and scaling an image having a circle overlay by default. It places the title, "Move and Scale" centered at the top of the screen.  A cancel button at the lower left corner and a choose button at the lower right corner.
     */
    func createSubViews() {
        
        /* create the scrollView to fit within the physical screen size
         */
        let screenRect:CGRect = UIScreen.main.bounds // get the device physical screen dimensions
        scrollView.frame = screenRect
                        
        scrollView.backgroundColor = backgroundColor
        
        scrollView.delegate = self;
        
        scrollView.minimumZoomScale = minimumZoomScale    // content cannot shrink
        
        scrollView.maximumZoomScale = maximumZoomScale   // content can grow 10x original size
                
        // resize the bottom view (z-order) to fit within the screen size and position it at the top left corner
        self.view.frame = CGRect(origin: .zero, size: screenRect.size)            
        self.view.addSubview(scrollView)
        
        // create the image view with the image
        imageView.image = imageToEdit
        imageView.contentMode = .scaleToFill
        scrollView.addSubview(imageView)
        
        /* create the overlay screen positioned over the entire screen having a square positioned at the center of the screen. The square side length is either the width or height of the screen size, whichever is smaller.  It's inset by 10 pixels.   Inside the square a circle is drawn to reveal the part of the image that will display in a circlewhen croped to the square's dimensions.
         */
        
        // Compute crop rectangle.
        cropRect = centerSquareRectInRect(layerSize: screenRect.size, withInsets: UIEdgeInsets(top: kOverlayInset, left: kOverlayInset, bottom: kOverlayInset, right: kOverlayInset))
        
        overlayView.frame = screenRect
        overlayView.isUserInteractionEnabled = false
        
        let overlayLayer = createOverlay(inBounds: cropRect, outBounds: screenRect)
        overlayView.layer.addSublayer(overlayLayer)
        self.view.addSubview(overlayView)
        
        /* add title, "Move and Scale" positioned at the top center of the screen
         */
        titleLabel = addTitleLabel(parentView: self.view)
                
        /* position the cancel button at the bottom left corner of the screen
         */
        cancelButton = addCancelButton(to: self.view, action:#selector(cancel))
        
        /* position the choose button at the bottom right corner of the screen
         */
        chooseButton = addChooseButton(to: self.view, action:#selector(choose))
        
    }
    
    /** Add Title Label
     *  adds the "Move and Scale" title centered at the top of the parent view.
     *
     *  @param parentView the view to add the title to.
     *
     *  @return the label view added
     */
    //-(UILabel*)addTitleLabel:(UIView*)parentView {
    func addTitleLabel(parentView: UIView) -> UILabel  {
        /*  define constants to create and position the title in the view.
         */
        let kTitleFrame = CGRect(origin: .zero, size: CGSize(width: 50, height: 27))
        
        let kTopSpace:CGFloat = 25.0
        
        let label = UILabel(frame: kTitleFrame)
                
        label.text = lString(key: "Edit.title", comment: "Localized edit tite")
                
        label.textColor = foregroundColor
        parentView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        /* center the title in the view and position it a short distance from the top
         */
        if #available(iOS 11.0, *) {            
            // iPhone X, et al, support using iOS11 Safe Area Layout Guide mechanism.
            label.centerXAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.centerXAnchor).isActive = true
            
            label.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor,constant: kTopSpace).isActive = true
        }
        else {
            
            label.centerXAnchor.constraint(equalTo: parentView.centerXAnchor).isActive = true
            
            label.topAnchor.constraint(equalTo: parentView.topAnchor,constant: kTopSpace).isActive = true
        }
        
        return label
    }
    
    /** Add Choose Button
     *  adds the button with the title "Choose" position at the bottom right corner of the parent view.
     *
     *  @param parentView The view to add the button to
     *  @param action     The method to call on the UIControlEventTouUpInside event
     *
     *  @return the button view added
     */
    func addChooseButton(to parentView: UIView,
                         action: Selector) -> UIButton {
        
        /* define constants to create and position the choose button on the bottom right corner of the parent view.
         */
        let kChooseFrame = CGRect(origin: .zero, size: CGSize(width: 75, height: 27))        
        let kChooseRightSpace:CGFloat = 25.0
        let kChooseBottomSpace:CGFloat = 50.0
        
        let button = UIButton(type: .system)
        
        button.frame = kChooseFrame;
        
        /* the button has a different title depending on whether it is displaying from the camera or the photo album picker and edit image.
         */
        
        if (isPresentingCamera) {
            button.setTitle(lString(key: "Button.choose.photoFromCamera", comment:"Local use photo"), for: .normal)            
        } else {
            button.setTitle(lString(key: "Button.choose.photoFromPicker", comment:"Local use picker"), for: .normal)    
        }
        
        button.setTitleColor(foregroundColor, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        
        parentView.addSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        /* ancher the choose button to the bottom right corner of the parent view.
         */
        if #available(iOS 11.0, *) {
            
            // iPhone X, et al, support using iOS11 Safe Area Layout Guide mechanism.
            
            button.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant:-kChooseBottomSpace).isActive = true
            
            button.rightAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.rightAnchor, constant:-kChooseRightSpace).isActive = true
        }
        else {
            button.topAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -kChooseBottomSpace).isActive = true
            
            button.rightAnchor.constraint(equalTo: parentView.rightAnchor, constant: -kChooseRightSpace).isActive = true
        }
        
        return button
        
    }
    
    /** Add Cancel Button
     *  adds the button with the title "Cancel" position at the bottom left corner of the parent view.
     *
     *  @param parentView The view to add the button to
     *  @param action     The method to call on the UIControlEventTouUpInside event
     *
     *  @return the button view added
     */
    func addCancelButton(to parentView: UIView,
                         action: Selector) -> UIButton {
        
        /* define constants to create and position the choose button on the bottom left corner of the parent view.
         */
    
        let kCancelFrame = CGRect(origin: .zero, size: CGSize(width: 50, height: 27))        
        let kCancelLeftSpace:CGFloat = 25.0
        let kCancelBottomSpace:CGFloat = 50.0
        
        let button = UIButton(type: .system)
        
        button.frame = kCancelFrame;
        
        /* the button has a different title depending on whether it is displaying from the camera or the photo album picker and edit image.
         */
        if (isPresentingCamera) {
            
            button.setTitle(lString(key: "Button.cancel.photoFromCamera", comment:"Local cancel photo"), for: .normal)   
            
        } else {
            
            button.setTitle(lString(key: "Button.cancel.photoFromPicker", comment:"Local cancel picker"), for: .normal)               
        }
        
        button.setTitleColor(foregroundColor, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        
        parentView.addSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        /* ancher the cancel button to the bottom left corner of the parent view.
         */
        if #available(iOS 11.0, *) {
            // iPhone X, et al, support using iOS11 Safe Area Layout Guide mechanism.
            
            button.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant:-kCancelBottomSpace).isActive = true
            
            button.leftAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leftAnchor, constant:kCancelLeftSpace).isActive = true
        }
        else {
            
            button.topAnchor.constraint(equalTo: parentView.bottomAnchor, 
                                        constant: -kCancelBottomSpace).isActive = true
            
            button.leftAnchor.constraint(equalTo: parentView.leftAnchor, 
                                         constant: kCancelLeftSpace).isActive = true
        }
        
        return button;
        
    }
    
    
    /** View For Zooming in ScrollView
     *  the imageView is the view for zooming the scroll view.
     *
     *  @param scrollView the scroll view with the request
     *
     *  @return the image view
     */
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    /**  Scroll View Did End Zooming
     *  Adjusts the scroll view's insets as the view enlarges.  As the scale enlarges the image, the insets shrink so that the edges do not move beyond the corresponding edge of the image mask when the it is scrolled.
     *
     *  @param sv    the scroll view
     *  @param view  the view that was zoomed
     *  @param scale the scale factor
     */
    public func scrollViewDidEndZooming(
        _ scrollView: UIScrollView,
        with view: UIView?,
        atScale scale: CGFloat
    ) {
        scrollView.contentInset = insetsForImage(imageSize: scrollView.contentSize, withFrame: cropRect.size, inView: UIScreen.main.bounds.size)
    }
    
    /* centerRect:
     */
    
    /** Center Rect
     *  retuns a rectangle's origin to position the inside rectangle centered within the enclosing one
     *
     *  @param insideRect  the inside rectangle
     *  @param outsideRect the rectangle enclosing the inside rectangle.
     *
     *  @return inside rectangle's origin to position it centered.
     */
    func center(rect insideRect: CGRect,
                inside outsideRect: CGRect) -> CGPoint  {
       
        var upperLeft = CGPoint.zero
        
        
        /* calculate the origin's y coordinate. */
        if (insideRect.size.height >= outsideRect.size.height) {
            
            upperLeft.y = round((insideRect.size.height - outsideRect.size.height) / 2)
            
        } else {
            
            upperLeft.y = -round((outsideRect.size.height - insideRect.size.height) / 2)
            
        }
        
        /* calculate the origin's x coordinate. */
        if (insideRect.size.width >= outsideRect.size.width) {
            
            upperLeft.x = round((insideRect.size.width - outsideRect.size.width) / 2)
            
        } else {
            
            upperLeft.x = -round((outsideRect.size.width - insideRect.size.width) / 2)
            
        }
        
        return upperLeft
        
    }
    
    /** Center Square Rectangle in Rectangle
     *  creates a square with the shortest input dimensions less the insets, and positions the x and y coordinates such that it's center is the same center as would be the rectangle created from the input size and its origin at (0,0).
     *
     *  @param layerSize the size of the layer to create the centered rectangle in
     *  @param inset     the rectangle's insets
     *
     *  @return the centered rectangle
     */
    
    func centerSquareRectInRect(layerSize: CGSize, 
                                withInsets inset: UIEdgeInsets) -> CGRect {
        
        var rect = CGRect.zero
        
        var length:CGFloat = 0
        var x:CGFloat = 0
        var y:CGFloat = 0
        
        /* if width is greater than height, swap the height and the width
         */
        
        if (layerSize.height < layerSize.width) {
            
            length = layerSize.height;
            
            x = (layerSize.width/2 - layerSize.height/2)+inset.left;
            
            y = inset.top;
            
        } else {
            
            
            length = layerSize.width;
            
            x = inset.left;
            
            y = (layerSize.height/2-layerSize.width/2)+inset.top;
            
        }
        
        rect = CGRect(x: x, y: y, width: length-inset.right-inset.left, height: length-inset.bottom-inset.top);
        
        
        return rect;
    }
    
    /** Create Overlay
     *  the overlay is the transparent view with the clear center to show how the image will appear when cropped. inBounds is the inside transparent crop region.  outBounds is the region that falls outside the inbound region and displays what's beneath it with dark transparency.
     *
     *  @param inBounds  the inside transparent crop rectangle
     *  @param outBounds the area outside inbounds.  In this solution it's always the screen dimensions.
     *
     *  @return the shape layer with a transparent circle and a darker region outside
     */
    // -(CAShapeLayer*)createOverlay:(CGRect)inBounds bounds:(CGRect)outBounds{
    
    func createOverlay(inBounds: CGRect,
                       outBounds: CGRect) -> CAShapeLayer {
        
        
        // create the circle so that it's diameter is the screen width and its center is at the intersection of the horizontal and vertical centers
        let circPath: UIBezierPath  = UIBezierPath(ovalIn: inBounds)
        
        // Create a rectangular path to enclose the circular path within the bounds of the passed in layer size.
        let rectPath: UIBezierPath  = UIBezierPath(roundedRect: outBounds, cornerRadius: 0)    
        
        rectPath.append(circPath)
        
        let rectLayer: CAShapeLayer = CAShapeLayer()
        
        // add the circle path within the rectangular path to the shape layer.
        rectLayer.path = rectPath.cgPath;
        
        rectLayer.fillRule = CAShapeLayerFillRule.evenOdd;
        
        rectLayer.fillColor = backgroundColor.cgColor
        
        rectLayer.opacity = overlayOpacity
        
        return rectLayer
    }
    
    /** insets for image with frame in view
     *  the goal of this routine is to calculate the insets so that the top and bottom of the image can align with the top and bottom of the frame when it is scrolled within the view.
     *
     *  @param imageSize height and width of the image
     *  @param frameSize size of the region where the image will be cropped to
     *  @param viewSize  size of the view where the image will display
     *
     *  @return <#return value description#>
     */
    //-(UIEdgeInsets)insetsForImage:(CGSize)imageSize withFrame:(CGSize)frameSize inView:(CGSize)viewSize {
    func insetsForImage(imageSize: CGSize,
                        withFrame frameSize: CGSize, 
                        inView viewSize: CGSize) -> UIEdgeInsets {
        var inset = UIEdgeInsets.zero
        var deltaInsets = UIEdgeInsets.zero
        
        var insideSize = frameSize
        
        /* compute the delta top and bottom inset if image height is less than the frame.
         */
        
        if (imageSize.height < frameSize.height) {
            
            insideSize.height = imageSize.height;
            
            deltaInsets.bottom = trunc((frameSize.height - insideSize.height))/2
            deltaInsets.top = deltaInsets.bottom
        }
        
        /* compute the delta left and right inset if image width is less than the frame.
         */
        
        if (imageSize.width < frameSize.width) {
            
            insideSize.width = imageSize.width;
            
            deltaInsets.left = trunc((frameSize.width - insideSize.width))/2
            deltaInsets.right = deltaInsets.left
        }
        
        /*  compute the inset by adding the image inset with respect to the frame to the inset of the frame with respect to the view.
         */
        inset.bottom = trunc(((viewSize.height - insideSize.height) / 2) + deltaInsets.top)
        inset.top = inset.bottom
        
        inset.left = trunc(((viewSize.width - insideSize.width) / 2) + deltaInsets.left)
        inset.right = inset.left
        
        return inset;
    }
    
    /// mark - action
    
    /** choose
     *  called when the user is finished with moving and scaling the image to select it as final.  It crops the image and sends the information to the delegate.
     *
     *  @param sender the button view tapped
     */
    @IBAction func choose(sender: UIButton) {
        var img: UIImage?
        var cropOrigin: CGPoint = .zero
                
        didChooseImage = true
        
        /* compute the crop rectangle based on the screens dimensions.
         */
        cropOrigin.x = trunc(scrollView.contentOffset.x + scrollView.contentInset.left);
        
        cropOrigin.y = trunc(scrollView.contentOffset.y + scrollView.contentInset.top);
        
        let screenCropRect = CGRect(x: cropOrigin.x, y: cropOrigin.y, width: cropRect.size.width, height: cropRect.size.height);
        
        img = imageView.image?.cropRectangle(cropRect: screenCropRect, inFrame:scrollView.contentSize)
        
        /* transpose the crop rectangle from the screen dimensions to the actual image dimensions.
         */
        let imageCropRect:CGRect? = {
            
            guard let image = imageView.image else  {return nil}
            return img?.transposeCropRect(cropRect: screenCropRect, fromRect: CGRect(origin: .zero, size: scrollView.contentSize), toRect: CGRect(origin: .zero, size: image.size))
        }()
        
        /* create the dictionary properties to pass to the delegate.
         */
        var info = [UIImagePickerController.InfoKey: Any]()
        
        info[.editedImage] = img
        info[.originalImage] =  imageView.image
        info[.mediaType] = kUTTypeImage
        info[.cropRect] = imageCropRect
        
        self.delegate?.swiftImagePickerController(self, didFinishPickingMediaWithInfo: info)
    }
    
    /** cancel
     *  the user has decided to snap another photo if presenting the camera, to choose another image from the album if presenting the album, or to exit the move and scale when only using it to crop an image.
     *
     *  @param sender the button view tapped
     */
    @IBAction func cancel(sender: UIButton) {        
        if (isDisplayFromPicker) {
            imagePicker?.popViewController(animated: false)            
        } else if (isPresentingCamera) {
            self.dismiss(animated: false)
        } else {
            self.delegate?.swiftImagePickerControllerDidCancel(self)         
        }
    }
    /* editImage: presents the move and scale view initialized with the input image.  This is only to be called from the presentCamera and presentPhotoPicker workflows after the user has captured an image or selected one.
     */
    /**
     *
     *
     *  @param image <#image description#>
     */
    internal func edit(image: UIImage) {
        
        imageToEdit = image
        
        self.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        //    [imagePicker setNavigationBarHidden:YES];
        
        //    [imagePicker pushViewController:self animated:NO];
        camera?.present(self, animated: true)        
    }
    
    /// mark - Public Interface
    
    /** present edit screen
     *  presents the move and scale window for a supplied image.  This use case is for when all that's required is to crop an image not to select one from the camera or photo album before cropping.
     *
     *  @param vc    view controller requesting presentation of the edit screen
     *  @param image the image to show in the edit screen
     */
    func presentEditScreen(vc: UIViewController,
                           with image: UIImage) {

        isDisplayFromPicker = false
        isPresentingCamera = false
        
        imageToEdit = image
        
        presentingVC = vc
        
        self.modalPresentationStyle = .fullScreen
        
        presentingVC?.present(self, animated: true)
    }
    
    /**
     *  instantiates the UIImagePickerController object and configures it to present the photo library picker.
     *
     *  @param vc the view controller requesting presentation of the photo library selection.
     */
    func selectFromPhotoLibrary(vc: UIViewController) {
        
        imagePicker = UIImagePickerController()
        
        imagePicker?.sourceType = .photoLibrary
        
        imagePicker?.mediaTypes = [kUTTypeImage as String] 
        imagePicker?.allowsEditing = false
        
        imagePicker?.modalPresentationStyle = .fullScreen
        
        isDisplayFromPicker = true
        
        presentingVC = vc
        
        imagePicker?.delegate = self
        
        presentingVC?.present(self,animated: true)
    }
    
    /**
     *  instantiates the UIImagePickerController object and configures it to present the camera.
     *
     *  @param vc the view controller requesting presentation of the camera.
     */
    func selectFromCamera(vc: UIViewController) {
        
        isPresentingCamera = true
        
        camera = MMSCameraViewController()
        
        //[[MMSCameraViewController alloc] initWithNibName:nil bundle:nil];
        
        camera?.delegate = self
        
        presentingVC = vc
        
        presentingVC?.present(self, animated: true)
    }
   
    
    /**
     *  returns a localized string based on the key.
     *
     *  @param key - the identifier for the string.
     *  @param comment - the help text for the key.
     *
     *  @return - returns the localized string identified by the key.
     */
    func lString(key: String, comment: String) -> String {
                
        return NSLocalizedString(key, tableName: "Localized", bundle: Bundle.main, value: "", comment: "")
    }
    
    /// mark - Camera setup and capture
    
   
    
    /*
     /// mark - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension SwiftProfileImagePicker: MMSCameraViewDelegate {
    
    public func cameraDidCaptureStillImage(_ image: UIImage, camera cameraController: MMSCameraViewController) {
        edit(image: image)
    }
}

// mark - UIImagePickerControllerDelegate

extension SwiftProfileImagePicker: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    /**  did finish picking media with info
     *  presents the move and scale screen with the selected image.
     *
     *  @param picker <#picker description#>
     *  @param info   <#info description#>
     */
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        imageToEdit = info[.originalImage] as? UIImage
        
        self.modalPresentationStyle = .fullScreen
        imagePicker?.setNavigationBarHidden(true, animated: true)

        imagePicker?.pushViewController(self, animated: false)
    }
    
    /** image picker controller did cancel
     *  this routine calls the equivalent this class's custome delegate method.
     *
     *  @param picker the image picker controller.
     */
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.delegate?.swiftImagePickerControllerDidCancel(self)
    }
}
