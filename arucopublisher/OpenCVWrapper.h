//
//  OpenCVWrapper.h
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 27.03.2023.
//

#ifndef OpenCVWrapper_h
#define OpenCVWrapper_h

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <SceneKit/SceneKit.h>
#import <UIKit/UIKit.h>


@interface ArucoCV : NSObject

+(NSMutableArray *) estimatePose:(CVPixelBufferRef)pixelBuffer withIntrinsics:(matrix_float3x3)intrinsics andMarkerSize:(Float64)markerSize;
@end

#endif /* OpenCVWrapper_h */
