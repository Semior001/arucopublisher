//
//  ArucoMarker.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 27.03.2023.
//

import Foundation

@objc class ArucoMarker: NSObject {
    var id: Int = 0
    var pose: FloatTriple
    var orientation: FloatTriple
    var corners: Corners? = nil
    var imageVectors: OrientationVectors?

    init(id: Int, pose: FloatTriple, orientation: FloatTriple, corners: Corners? = nil, imageVectors: OrientationVectors? = nil) {
        self.id = id
        self.pose = pose
        self.orientation = orientation
        self.corners = corners
        self.imageVectors = imageVectors
        super.init()
    }
}


@objc class FloatTriple: NSObject {
    var x: Float
    var y: Float
    var z: Float

    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
        super.init()
    }
}

@objc class Corners: NSObject {
    var topLeft: FloatTriple
    var topRight: FloatTriple
    var bottomRight: FloatTriple
    var bottomLeft: FloatTriple
    var imageWidth: Int
    var imageHeight: Int

    init(topLeft: FloatTriple, topRight: FloatTriple, bottomRight: FloatTriple, bottomLeft: FloatTriple, imageWidth: Int, imageHeight: Int) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        super.init()
    }
}

@objc class OrientationVectors: NSObject {
    var base: CGPoint
    var x: CGPoint
    var y: CGPoint
    var z: CGPoint
    var imageWidth: Int
    var imageHeight: Int

    init(base: CGPoint, x: CGPoint, y: CGPoint, z: CGPoint, imageWidth: Int, imageHeight: Int) {
        self.base = base
        self.x = x
        self.y = y
        self.z = z
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        super.init()
    }
}
