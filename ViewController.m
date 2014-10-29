//
//  ViewController.m
//  opencv
//
//  Created by Bo Wu on 9/17/14.
//  Copyright (c) 2014 Bo Wu. All rights reserved.
//

#import "ViewController.h"
#import <GalileoControl/GalileoControl.h>


@interface ViewController ()

@end

@implementation ViewController
@synthesize imageView;
@synthesize photoCamera;
@synthesize takePhotoButton;
@synthesize startCaptureButton;
@synthesize saveButton;
@synthesize videoCamera;
@synthesize panButton;

int board_w;
int board_h;
cv::Size board_sz;
float square_sz = 50;
int imageCount = 0;

//imapge points
std::vector<std::vector<cv::Point2f> > imagePoints(25);
cv::Mat cameraMatrix, distCoeffs;
cv::Size imageSize;

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Initial the photo camera
    
    photoCamera = [[CvPhotoCamera alloc]
                   initWithParentView:imageView];
    photoCamera.delegate = self;
    photoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    photoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetPhoto;
    photoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    
    /*
    //Initial the video camera
    videoCamera = [[CvVideoCamera alloc]initWithParentView:imageView];
    videoCamera.delegate = self;
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 30;
    
    isCapturing = NO;
    */
}

//UIButton for taking photo
- (IBAction)takePhotoButtonPressed:(id)sender
{
    [photoCamera takePicture];
    
}

//UIButton for starting capture video
-(IBAction)startCaptureButtonPressed:(id)sender
{
    [photoCamera start];
    [self.view addSubview:imageView];
    [takePhotoButton setEnabled:YES];
    [startCaptureButton setEnabled:NO];

}


- (void)photoCamera:(CvPhotoCamera*)camera
      capturedImage:(UIImage *)image;
{
    [camera stop];
    
    result = [[UIImageView alloc] initWithFrame:imageView.bounds];
    UIImage* resultImage = image;
    [result setImage:resultImage];
    [self.view addSubview:result];
    
    [takePhotoButton setEnabled:NO];
    [startCaptureButton setEnabled:YES];
}



- (void)photoCameraCancel:(CvPhotoCamera*)camera;
{
}

//Save photo in to album
- (IBAction)saveButtonPressed:(id)sender
{
    if (result.image != nil)
    {
        UIImageWriteToSavedPhotosAlbum(result.image, self, nil, NULL);
        
        // Alert window
        UIAlertView *alert = [UIAlertView alloc];
        alert = [alert initWithTitle:@"Status"
                             message:@"Saved to the Gallery!"
                            delegate:nil
                   cancelButtonTitle:@"Continue"
                   otherButtonTitles:nil];
        [alert show];
    }
}


-(IBAction)startCaptureVideoButtonPressed:(id)sender
{
    [videoCamera start];
    isCapturing = YES;
}

-(IBAction)stopCaptureVideoButtonPressed:(id)sender
{
    [videoCamera stop];
    isCapturing = NO;
}


-(IBAction)panButton:(id)sender{
    
    GCPositionControl* panPositionControl = [[GCGalileo sharedGalileo] positionControlForAxis:GCControlAxisPan];
    [panPositionControl incrementTargetPosition:15.0 notifyDelegate:nil waitUntilStationary:NO];
    
}

//Image processing for camera calibration

- (void)processImage:(cv::Mat&)image
{
    
    //set board width
    board_w = 7;
    //set board height
    board_h = 7;
    //cv::Mat next = image;
    //board size equal to board_w*board_h
    board_sz = cvSize(board_w, board_h);
    

//    clock_t prevTimestamp = 0;
    
    //maping corners on the cheese board
    const cv::Scalar RED(0,0,255), GREEN(0,255,0);
//    const char ESC_KEY = 27;

    //for(int i = 0;;++i)
    //{
        
        //Capturing the images for calibration
        if (imagePoints.size() >= 25){
            if ([self runCalibrationAndOutputWithImageSize:imageSize andCameraMatrix:cameraMatrix andDist:distCoeffs andImagePoints:imagePoints]) {
                return;
            }
        }
        
        imageSize = image.size();
        
        std::vector<cv::Point2f> pointBuf;
        NSLog(@"Calibation........");
        bool found = findChessboardCorners( image, board_sz, pointBuf,
                                         CV_CALIB_CB_ADAPTIVE_THRESH | CV_CALIB_CB_FAST_CHECK | CV_CALIB_CB_NORMALIZE_IMAGE);
            if (found) {
                cv::Mat viewGray;
                cv::cvtColor(image, viewGray, cv::COLOR_BGR2GRAY);
                cornerSubPix( viewGray, pointBuf, cvSize(11,11),
                         cvSize(-1,-1), cv::TermCriteria(CV_TERMCRIT_EPS+CV_TERMCRIT_ITER, 30, 0.1));
                //std::cout<<pointBuf[1]<<' ';
                
            }
    
    
        
        //std::cout<<imagePoints[1]<<' ';
    
        drawChessboardCorners( image, board_sz, cv::Mat(pointBuf), found);
    if(!pointBuf.empty()){
        imagePoints.push_back(pointBuf);
        imageCount++;
    }
    //std::cout<<imageCount<<' ';
    
}

- (double)computeReprojectionErrorsWithobjectPoints:(std::vector<std::vector<cv::Point3f>>&) objectPoints
                                     andImagePoints:(std::vector<std::vector<cv::Point2f>>&) imagePoints
                                        andRotation:(std::vector<cv::Mat>&) rvecs
                                     andTranslation:(std::vector<cv::Mat>&) tvecs
                                    andCameraMatrix:(cv::Mat&) cameraMatrix
                                            andDist:(cv::Mat&) distCoeffs
                                       andPerErrors:(std::vector<float>&) perViewErrors
{
    std::vector<cv::Point2f> imagePoints2;
    int i, totalPoints = 0;
    double totalErr = 0, err;
    perViewErrors.resize(objectPoints.size());
    
    for( i = 0; i < (int)objectPoints.size(); ++i )
    {
        projectPoints(cv::Mat(objectPoints[i]), rvecs[i], tvecs[i], cameraMatrix,
                      distCoeffs, imagePoints2);
        err = norm(cv::Mat(imagePoints[i]), cv::Mat(imagePoints2), CV_L2);
        
        int n = (int)objectPoints[i].size();
        perViewErrors[i] = (float) std::sqrt(err*err/n);
        totalErr        += err*err;
        totalPoints     += n;
    }
    return std::sqrt(totalErr/totalPoints);;
}

- (void) calcBoardCornerPositionsWithBoardSize:(cv::Size &)boardSize
                                 andSquareSize:(float)squareSize
                                     andConers:(std::vector<cv::Point3f>&) corners
{
    corners.clear();
}

- (BOOL) runCalibrationWithImageSize:(cv::Size &)imageSize
                     andCameraMatrix:(cv::Mat &)cameraMatrix
                             andDist:(cv::Mat &)distCoeffs
                      andImagePoints:(std::vector<std::vector<cv::Point2f>> &)imagePoints
                         andRotation:(std::vector<cv::Mat>&) rvecs
                      andTranslation:(std::vector<cv::Mat>&) tvecs
                            andError:(std::vector<float>&)reprojErrs
                         andTotalErr:(double &)totalAvgErr
{
    cameraMatrix = cv::Mat::eye(3, 3, CV_64F);
    if (CV_CALIB_FIX_ASPECT_RATIO) {
        cameraMatrix.at<double>(0,0) = 1.0;
    }
    
    distCoeffs = cv::Mat::zeros(8, 1, CV_64F);
    
    std::vector<std::vector<cv::Point3f> > objectPoints(1);
    [self calcBoardCornerPositionsWithBoardSize:board_sz andSquareSize:square_sz andConers:objectPoints[0]];
    
    objectPoints.resize(imagePoints.size(),objectPoints[0]);
    
    double rms = calibrateCamera(objectPoints, imagePoints, imageSize, cameraMatrix,
                                 distCoeffs, rvecs, tvecs, 1|CV_CALIB_FIX_K4|CV_CALIB_FIX_K5);
    
    NSLog(@"Re-projection error: %f",rms);
    
    bool ok = checkRange(cameraMatrix) && checkRange(distCoeffs);
    
    totalAvgErr = [self computeReprojectionErrorsWithobjectPoints:objectPoints andImagePoints:imagePoints andRotation:rvecs andTranslation:tvecs andCameraMatrix:cameraMatrix andDist:distCoeffs andPerErrors:reprojErrs];
    
    return ok;
}

- (void) outputDataWithImageSize:(cv::Size &)imageSize
                 andCameraMatrix:(cv::Mat &)cameraMatrix
                         andDist:(cv::Mat &)distCoeffs
                     andRotation:(std::vector<cv::Mat>&) rvecs
                  andTranslation:(std::vector<cv::Mat>&) tvecs
                        andError:(std::vector<float>&)reprojErrs
                  andImagePoints:(std::vector<std::vector<cv::Point2f>> &)imagePoints
                     andTotalErr:(double &)totalAvgErr
{
    NSLog(@"image width: %d", imageSize.width);
    NSLog(@"image height: %d", imageSize.height);
    NSLog(@"Board width: %d", board_sz.width);
    NSLog(@"Board height: %d", board_sz.height);
}

- (BOOL) runCalibrationAndOutputWithImageSize:(cv::Size &)imageSize
                              andCameraMatrix:(cv::Mat &)cameraMatrix
                                      andDist:(cv::Mat &)distCoeffs
                               andImagePoints:(std::vector<std::vector<cv::Point2f>> &)imagePoints
{
    std::vector<cv::Mat> rvecs, tvecs;
    std::vector<float> reprojErrs;
    double totalAvgErr = 0;
    
    BOOL ok;
    ok = [self runCalibrationWithImageSize:imageSize andCameraMatrix:cameraMatrix andDist:distCoeffs andImagePoints:imagePoints andRotation:rvecs andTranslation:tvecs andError:reprojErrs andTotalErr:totalAvgErr];
    
    if (ok) {
        [self outputDataWithImageSize:imageSize andCameraMatrix:cameraMatrix andDist:distCoeffs andRotation:rvecs andTranslation:tvecs andError:reprojErrs andImagePoints:imagePoints andTotalErr:totalAvgErr];
    }
    
    return ok;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

























