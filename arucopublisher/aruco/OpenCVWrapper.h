//
// Created by Yelshat Duskaliyev on 27.03.2023.
//

#ifndef ARUCOPUBLISHER_OPENCVWRAPPER_H
#define ARUCOPUBLISHER_OPENCVWRAPPER_H


#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <SceneKit/SceneKit.h>
#import <UIKit/UIKit.h>

@class NSArray;

@interface OpenCVWrapper : NSObject

// detectAndLocalize accepts:
// - pixel buffer,
// - camera intrinsics (in form of a matrix of floats),
// - distortion coefficients (in form of an array of floats)
// - and marker size as an input and returns a list of ArucoMarker
+(NSArray *) detectAndLocalize:(CVPixelBufferRef)pixelBuffer
                withIntrinsics:(NSArray*) intrinsics
     andDistortionCoefficients:(NSArray*) distortionCoefficients
                 andMarkerSize:(Float64) markerSize;

// linkedAndLoaded constantly returns true, used just to be sure, that the file is linked and loaded
+(BOOL) linkedAndLoaded;

@end

#endif //ARUCOPUBLISHER_OPENCVWRAPPER_H
