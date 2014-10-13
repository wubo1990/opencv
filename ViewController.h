//
//  ViewController.h
//  opencv
//
//  Created by Bo Wu on 9/17/14.
//  Copyright (c) 2014 Bo Wu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/ios.h>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/calib3d/calib3d.hpp>
#import <opencv2/core/core_c.h>
#import <opencv2/core/core.hpp>


@interface ViewController : UIViewController<CvPhotoCameraDelegate,
                                            UIImagePickerControllerDelegate,
                                            UINavigationControllerDelegate,
                                            UIPopoverControllerDelegate,
                                            CvVideoCameraDelegate>
{
    CvPhotoCamera* photoCamera;
    CvVideoCamera* videoCamera;
    cv::VideoCapture inputCapture;
    UIImageView* result;
    BOOL isCapturing;
}

@property (nonatomic, strong) CvPhotoCamera* photoCamera;
@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet UIToolbar* toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* saveButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* takePhotoButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* startCaptureButton;

@property (nonatomic, weak) IBOutlet UIBarButtonItem* startCaptureVideoButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* stopCaptureVideoButton;


-(IBAction)takePhotoButtonPressed:(id)sender;
-(IBAction)startCaptureButtonPressed:(id)sender;
-(IBAction)saveButtonPressed:(id)sender;

-(IBAction)startCaptureVideoButtonPressed:(id)sender;
-(IBAction)stopCaptureVideoButtonPressed:(id)sender;


@end
