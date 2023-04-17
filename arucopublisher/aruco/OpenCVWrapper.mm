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
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50);

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    cv::Mat image(height, width, CV_8UC1, baseaddress, CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0));

    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f>> corners;

    cv::aruco::detectMarkers(image, dictionary, corners, ids);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return {corners, ids};
}

const float orientationVectorLength = 1;

static Triple<std::vector<cv::Vec3d>, std::vector<cv::Vec3d>, std::vector<std::vector<cv::Point2f>>> estimatePosesAndOrientation(
        std::vector<std::vector<cv::Point2f>> corners,
        NSArray *intrinsics, Float64 markerSize
) {
    cv::Mat intrinMat(3, 3, CV_64F);

    // convert intrinsics, they're provided in linear array
    intrinMat.at<Float64>(0, 0) = [intrinsics[0] doubleValue];
    intrinMat.at<Float64>(0, 1) = [intrinsics[1] doubleValue];
    intrinMat.at<Float64>(0, 2) = [intrinsics[2] doubleValue];
    intrinMat.at<Float64>(1, 0) = [intrinsics[3] doubleValue];
    intrinMat.at<Float64>(1, 1) = [intrinsics[4] doubleValue];
    intrinMat.at<Float64>(1, 2) = [intrinsics[5] doubleValue];
    intrinMat.at<Float64>(2, 0) = [intrinsics[6] doubleValue];
    intrinMat.at<Float64>(2, 1) = [intrinsics[7] doubleValue];
    intrinMat.at<Float64>(2, 2) = [intrinsics[8] doubleValue];

    cv::Mat distCoeffs = cv::Mat::zeros(8, 1, CV_64F);

    std::vector<cv::Vec3d> rvecs, tvecs;

    cv::aruco::estimatePoseSingleMarkers(corners, static_cast<float>(markerSize), intrinMat, distCoeffs, rvecs, tvecs);

    // project points
    std::vector<std::vector<cv::Point2f>> imagePoints;

    for (int i = 0; i < rvecs.size(); i++) {
        std::vector<cv::Point2f> imagePointsForMarker;
        cv::projectPoints(
                std::vector<cv::Point3f>{
                        {0, 0, 0},
                        {orientationVectorLength, 0, 0},
                        {0, orientationVectorLength, 0},
                        {0, 0, orientationVectorLength}
                },
                rvecs[i],
                tvecs[i],
                intrinMat,
                distCoeffs,
                imagePointsForMarker
        );
        imagePoints.push_back(imagePointsForMarker);
    }

    return {rvecs, tvecs, imagePoints};
}


// detectAndLocalize accepts an image as an input and returns a list of ArucoMarker
+ (NSArray *)detectAndLocalize:(CVPixelBufferRef)pixelBuffer
                withIntrinsics:(NSArray *)intrinsics
                    markerSize:(Float64)markerSize {

    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);

    // detect markers
    auto [corners, ids] = detect(static_cast<int>(width), static_cast<int>(height), pixelBuffer);

    if (ids.empty()) {
        return @[];
    }

    NSMutableArray *arucos = [NSMutableArray new];
    if (ids.size() == 0) {
        return arucos;
    }

    auto [rvecs, tvecs, imagePoints] = estimatePosesAndOrientation(
            corners,
            intrinsics,
            markerSize
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
               {static_cast<float>(imagePoints[i][0].x), static_cast<float>(imagePoints[i][0].y)},
               {static_cast<float>(imagePoints[i][1].x), static_cast<float>(imagePoints[i][1].y)},
               {static_cast<float>(imagePoints[i][2].x), static_cast<float>(imagePoints[i][2].y)},
               {static_cast<float>(imagePoints[i][3].x), static_cast<float>(imagePoints[i][3].y)}
       };

        aruco.imageWidth = static_cast<int>(width);
        aruco.imageHeight = static_cast<int>(height);

        [arucos addObject:aruco];
    }

    return arucos;
}

+ (BOOL)linkedAndLoaded {
    return YES;
}

@end
