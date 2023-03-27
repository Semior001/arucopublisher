//
// Created by Yelshat Duskaliyev on 27.03.2023.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define OPENCV_STITCHING_STITCHER_HPP
#define OPENCV_STITCHING_BLENDERS_HPP
#define OPENCV_STITCHING_SEAM_FINDERS_HPP
#define OPENCV_STITCHING_EXPOSURE_COMPENSATE_HPP

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#include "opencv2/aruco.hpp"
#include "OpenCVWrapper.h"
#include "Bridging.h"

@implementation ArucoMarker
@end

@implementation OpenCVWrapper

template<typename T, typename U>
struct Pair {
    T first;
    U second;
};

template<typename T, typename U, typename K>
struct Triple {
    T first;
    U second;
    K third;
};

static Pair<std::vector<std::vector<cv::Point2f>>, std::vector<int>> detect(int width, int height, CVPixelBufferRef pixelBuffer) {
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_5X5_250);

    // grey scale channel at 0
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    cv::Mat mat(height, width, CV_8UC1, baseaddress, 0);

    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f>> corners;

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return {corners, ids};
}

const double orientationVectorLength = 1;

static Triple<std::vector<cv::Vec3d>, std::vector<cv::Vec3d>, std::vector<cv::Mat>> estimatePosesAndOrientation(
        std::vector<std::vector<cv::Point2f>> corners,
        NSArray *intrinsics, NSArray *distortionCoefficients, Float64 markerSize
) {
    cv::Mat intrinMat(3,3,CV_64F);

    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            intrinMat.at<double>(i,j) = [intrinsics[static_cast<NSUInteger>(i)][static_cast<NSUInteger>(j)] doubleValue];
        }
    }

    std::vector<cv::Vec3d> rvecs, tvecs;
    cv::Mat distCoeffs(8, 1, CV_64F);

    for (int i = 0; i < 8; i++) {
        distCoeffs.at<double>(i,0) = [distortionCoefficients[static_cast<NSUInteger>(i)] doubleValue];
    }

    cv::aruco::estimatePoseSingleMarkers(corners, static_cast<float>(markerSize), intrinMat, distCoeffs, rvecs, tvecs);
    NSLog(@"found: rvecs.size(): %lu", rvecs.size());

    // project points
    std::vector<cv::Mat> imagePoints;

    for (int i = 0; i < rvecs.size(); i++) {
        cv::Mat axesPointsMat = cv::Mat::zeros(4, 3, CV_64F);

        // 0, 0, 0
        // orientation vector length, 0, 0
        // 0, orientation vector length, 0
        // 0, 0, orientation vector length
        axesPointsMat.at<double>(1, 0) = orientationVectorLength;
        axesPointsMat.at<double>(2, 1) = orientationVectorLength;
        axesPointsMat.at<double>(3, 2) = orientationVectorLength;

        cv::fisheye::projectPoints(
                axesPointsMat,
                rvecs[i],
                tvecs[i],
                intrinMat,
                distCoeffs,
                imagePoints[i]
        );
    }

    return {rvecs, tvecs, imagePoints};
}


// detectAndLocalize accepts an image as an input and returns a list of ArucoMarker
+(NSArray *)detectAndLocalize:(CVPixelBufferRef)pixelBuffer
               withIntrinsics:(NSArray *)intrinsics
       distortionCoefficients:(NSArray *)distortionCoefficients
                   markerSize:(Float64) markerSize {

    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);

    // detect markers
    auto [corners, ids] = detect(static_cast<int>(width), static_cast<int>(height), pixelBuffer);

    if (ids.empty()) {
        return @[];
    }

    NSMutableArray *arucos = [NSMutableArray new];
    if(ids.size() == 0) {
        return arucos;
    }

    auto [rvecs, tvecs, imagePoints] = estimatePosesAndOrientation(
            corners,
            intrinsics, distortionCoefficients, markerSize
    );

    for (int i = 0; i < ids.size(); i++) {
        ArucoMarker *aruco = [ArucoMarker new];
        aruco.id = ids[i];

        aruco.position = {
                static_cast<float>(tvecs[i][0]),
                static_cast<float>(tvecs[i][1]),
                static_cast<float>(tvecs[i][2])
        };

        aruco.orientation = {
                static_cast<float>(rvecs[i][0]),
                static_cast<float>(rvecs[i][1]),
                static_cast<float>(rvecs[i][2])
        };

        aruco.corners = {
                {static_cast<float>(corners[i][0].x), static_cast<float>(corners[i][0].y)},
                {static_cast<float>(corners[i][1].x), static_cast<float>(corners[i][1].y)},
                {static_cast<float>(corners[i][2].x), static_cast<float>(corners[i][2].y)},
                {static_cast<float>(corners[i][3].x), static_cast<float>(corners[i][3].y)}
        };

        aruco.imageVectors = {
                {
                        static_cast<float>(imagePoints[i].at<double>(0, 0)),
                        static_cast<float>(imagePoints[i].at<double>(0, 1))
                },
                {
                        static_cast<float>(imagePoints[i].at<double>(1, 0)),
                        static_cast<float>(imagePoints[i].at<double>(1, 1))
                },
                {
                        static_cast<float>(imagePoints[i].at<double>(2, 0)),
                        static_cast<float>(imagePoints[i].at<double>(2, 1))
                },
                {
                        static_cast<float>(imagePoints[i].at<double>(3, 0)),
                        static_cast<float>(imagePoints[i].at<double>(3, 1))
                }
        };

        aruco.imageWidth = static_cast<int>(width);
        aruco.imageHeight = static_cast<int>(height);

        [arucos addObject:aruco];
    }

    return arucos;
}

+(BOOL)linkedAndLoaded { return YES; }

@end
